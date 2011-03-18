require 'socket'
require 'timeout'
require 'uri'

require File.expand_path(File.dirname(__FILE__) + '/response')
require File.expand_path(File.dirname(__FILE__) + '/exception')
require File.expand_path(File.dirname(__FILE__) + '/helpers')
require File.expand_path(File.dirname(__FILE__) + '/version')

module RTSP

  # This class allows for building and sending the request message strings that
  # make up RTSP methods.  Clients and Servers use these for building and sending
  # the request messages to communicate in RTSP.
  class Request
    include RTSP::Helpers

    RTSP_ACCEPT_TYPE = "application/sdp"
    RTP_DEFAULT_CLIENT_PORT = 9000
    RTP_DEFAULT_PACKET_TYPE = "RTP/AVP"
    RTP_DEFAULT_ROUTING = "unicast"
    RTSP_DEFAULT_SEQUENCE_NUMBER = 1
    RTSP_DEFAULT_NPT = "0.000-"
    RTSP_DEFAULT_LANGUAGE = "en-US"
    MAX_BYTES_TO_RECEIVE = 3000
    USER_AGENT = "RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})"
    DEFAULT_TIMEOUT = 30

    # Creates an instance of an RTSP::Request object and sends the message
    # over the socket.
    #
    # @param [Hash] args
    # @return [RTSP::Response]
    def self.execute args
      new(args).execute
    end

    # Required arguments:
    # * :method
    # * :resource_url
    # Optional arguments:
    # * :body
    # * :timeout
    # * :socket
    # * :headers
    #
    # @param [Hash] args
    # @option args [Symbol] :method The RTSP method to build and send.
    # @option args [String] :resource_url The URL to communicate to.
    # @option args [String] :body Content to send as the body of the message.
    # Generally this will be a String of some sort, but could be binary data as
    # well.  Default is nil.
    # @option args [Fixnum] :timeout Number of seconds to timeout after trying
    # to send the message of the socket.  Defaults to 2.
    # @option args [Socket] :socket Optional; socket to use to communicate over.
    # @option args [Hash] :headers RTSP headers to add to the request.
    def initialize args
      @method =  args[:method] or raise ArgumentError, "must pass :method"
      @body =    args[:body]    || nil
      @timeout = args[:timeout] || DEFAULT_TIMEOUT

      if args[:resource_url].is_a?(String)
        @resource_uri = build_resource_uri_from args[:resource_url]
      elsif args[:resource_url].is_a?(URI)
        @resource_uri = args[:resource_url]
      else
        raise ArgumentError, "must pass :resource_url"
      end

      # TODO: if URI scheme = rtspu, use UDPSocket
      @socket = args[:socket] || TCPSocket.new(@resource_uri.host, @resource_uri.port)
      @headers = build_headers_from args[:headers]
    end

    # Takes headers passed in on init and combines them with default headers for
    # the method type that the request is being made for.  If @body was set on
    # init, this adds the Content-Length header based on the size of the body.
    #
    # @param [Hash] user_headers
    # @return [Hash] All of the headers to be used for the request.
    def build_headers_from user_headers
      new_headers = user_headers || {}

      if @body
        new_headers[:content_length] = @body.length
      end

      new_headers[:cseq] ||= RTSP_DEFAULT_SEQUENCE_NUMBER
      new_headers[:user_agent] ||= USER_AGENT
      headers = default_headers
      headers.merge! new_headers
    end

    # Returns the required/default headers for the provided method.
    #
    # @return [Hash] The default headers for the given method.
    def default_headers
      case @method
      when :describe
        { :accept => RTSP_ACCEPT_TYPE }
      when :announce
        { :content_type => RTSP_ACCEPT_TYPE }
      when :setup
        transport = "#{RTP_DEFAULT_PACKET_TYPE};"
        transport << "#{RTP_DEFAULT_ROUTING};"
        transport << "client_port=#{RTP_DEFAULT_CLIENT_PORT}-#{RTP_DEFAULT_CLIENT_PORT + 1}"
        { :transport => transport }
      when :play
        { :range => "npt=#{RTSP_DEFAULT_NPT}" }
      else
        {}
      end
    end

    # @return [RTSP::Response]
    def execute
      RTSP::Client.log "Sending #{@method.to_s.upcase} to #{@resource_uri}"
      response = send_message
      RTSP::Client.log "Received response:"

      if response
        response.to_s.each_line { |line| RTSP::Client.log line.strip }
      end

      response
    end

    # @return [String] The request message to send.
    def message
      # < 1.9.2 fix: use #to_s on a Symbol in order to call #upcase.
      message = "#{@method.to_s.upcase} #{@resource_uri} RTSP/#{DEFAULT_VERSION}\r\n"
      message << headers_to_s(@headers)
      message << "\r\n"
      message << "#{@body}" unless @body.nil?

      message.each_line { |line| RTSP::Client.log line.strip }

      message
    end

    # Sends the message over the socket.
    #
    # @return [RTSP::Response]
    def send_message
      begin
        Timeout::timeout(@timeout) do
          @socket.send(message, 0)
          recv
        end
      rescue Timeout::Error
        raise RTSP::Exception, "Request took more than #{@timeout} seconds to send."
      end
    end

    # @return [RTSP::Response]
    def recv
      socket_data = @socket.recvfrom MAX_BYTES_TO_RECEIVE
      response = RTSP::Response.new socket_data.first

      response
    end

=begin
    def connect
      timeout(@timeout) { @socket = TCPSocket.new(@host, @port) } #rescue @socket = nil
    end

    def connected?
      @socket == nil ? true : false
    end

    def disconnect
      timeout(@timeout) { @socket.close } rescue @socket = nil
    end
=end

    # Turns headers from Hash(es) into a String, where each element
    # is a String in the form: [Header Type]: value(s)\r\n.
    #
    # @param [Hash] headers The headers to put to string.
    # @return [String]
    def headers_to_s headers
      header_string = headers.inject("") do |result, (key, value)|
        header_name = key.to_s.split(/_/).map { |header| header.capitalize }.join('-')

        header_name = "CSeq" if header_name == "Cseq"

        if value.is_a?(Hash) || value.is_a?(Array)
          if header_name == "Content-Type"
            values = values_to_s(value, ", ")
          else
            values = values_to_s(value)
          end

          result << "#{header_name}: #{values}\r\n"
        else
          result << "#{header_name}: #{value}\r\n"
        end

        result
      end

      arr = header_string.split "\r\n"
      # Move the Session header to the top
      session_index = arr.index { |a| a =~ /Session/ }
      unless session_index.nil?
        session = arr.delete_at(session_index)
        arr.unshift(session)
      end

      # Move the User-Agent header to the top
      user_agent_index = arr.index { |a| a =~ /User-Agent/ }
      user_agent = arr.delete_at(user_agent_index)
      arr.unshift(user_agent)

      # Move the CSeq header to the top
      cseq_index = arr.index { |a| a =~ /CSeq/ }
      cseq = arr.delete_at(cseq_index)
      arr.unshift(cseq)

      # Put it all back to a String
      header_string = arr.join("\r\n")
      header_string << "\r\n"
    end

    # Turns header values into a single string.
    #
    # @param [] values The header values to put to string.
    # @param [String] separator The character to use to separate multiple values
    # that define a header.
    # @return [String] The header values as a single string.
    def values_to_s(values, separator=";")
      result = values.inject("") do |values_string, (header_field, header_field_value)|
        if header_field.is_a? Symbol
          values_string << "#{header_field}=#{header_field_value}"
        elsif header_field.is_a? Hash
          values_string << values_to_s(header_field)
        else
          values_string << header_field.to_s
        end

        values_string + separator
      end

      result.sub!(/#{separator}$/, '') if result.end_with? separator
    end
  end
end
