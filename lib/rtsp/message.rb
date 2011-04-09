require_relative 'helpers'
require_relative 'exception'
require_relative 'version'

module RTSP

  # This class is responsible for building a single RTSP message that can be
  # used by both clients and servers.
  #
  # If you need to add a new message type, you can simply add to the supported
  # list by:
  #    RTSP::Message.message_types << :my_new_type
  class Message
    include RTSP::Helpers

    RTSP_ACCEPT_TYPE = "application/sdp"
    RTSP_DEFAULT_NPT             = "0.000-"
    RTSP_DEFAULT_SEQUENCE_NUMBER = 1
    USER_AGENT                   =
        "RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})"

    @message_types = [
        :announce,
            :describe,
            :get_parameter,
            :options,
            :play,
            :pause,
            :record,
            :redirect,
            :set_parameter,
            :setup,
            :teardown
    ]

    # TODO: define #describe somewhere so I can actually test that method.
    class << self

      # Lists the method/message types this class can create.
      # @return [Array<Symbol>]
      attr_accessor :message_types

      # Make sure the class responds to our message types.
      #
      # @param [Symbol] method
      def respond_to?(method)
        @message_types.include?(method) || super
      end

      # Creates a new message based on the given method type and URI.
      #
      # @param [Symbol] method
      # @param [Array] args
      # @return [RTSP::Message]
      def method_missing(method, *args)
        request_uri = args.first

        if @message_types.include? method
          self.new(method, request_uri)
        else
          super
        end
      end
    end

    attr_reader :method_type
    attr_reader :request_uri
    attr_reader :headers
    attr_reader :body
    attr_writer :rtsp_version

    # @param [Symbol] :method_type The RTSP method to build and send.
    # @param [String] request_uri The URL to communicate to.
    def initialize(method_type, request_uri)
      @method_type = method_type
      @request_uri = build_resource_uri_from request_uri
      @headers     = default_headers
      @body        = ""
      @version     = DEFAULT_VERSION
    end

    # Adds the header and its value to the list of headers for the message.
    #
    # @param [Symbol] type The header type.
    # @param [] value The value to set the header field to.
    def header(type, value)
      if type.is_a? Symbol
        headers[type] = value
      else
        raise RTSP::Exception, "Header type must be a Symbol (i.e. :cseq)."
      end
    end

    def with_headers(new_headers)
      add_headers new_headers

      self
    end

    def add_headers(new_headers)
      @headers.merge! new_headers
    end

    def with_body(new_body)
      add_body new_body

      self
    end

    def add_body new_body
      add_headers({ content_length: new_body.length })
      @body = new_body
    end

    # @param [String] value Content to send as the body of the message.
    # Generally this will be a String of some sort, but could be binary data as
    # well. Also, this adds the Content-Length header to the header list.
    def body= value
      add_body value
    end

    # @return [String] The message as a String.
    def to_s
      message.to_s
    end

    ###########################################################################
    # PRIVATES
    private

    # Builds the request message to send to the server/client.
    #
    # @return [String]
    def message
      message = "#{@method_type.to_s.upcase} #{@request_uri} RTSP/#{@version}\r\n"
      message << headers_to_s(@headers)
      message << "\r\n"
      message << "#{@body}" unless @body.nil?

      #message.each_line { |line| RTSP::Client.log line.strip }

      message
    end

    # Returns the required/default headers for the provided method.
    #
    # @return [Hash] The default headers for the given method.
    def default_headers
      headers = {}

      headers[:cseq] ||= RTSP_DEFAULT_SEQUENCE_NUMBER
      headers[:user_agent] ||= USER_AGENT

      case @method_type
      when :describe
        headers[:accept] = RTSP_ACCEPT_TYPE
      when :announce
        headers[:content_type] = RTSP_ACCEPT_TYPE
      when :play
        headers[:range] = "npt=#{RTSP_DEFAULT_NPT}"
      when :get_parameter
        headers[:content_type] = 'text/parameters'
      when :set_parameter
        headers[:content_type] = 'text/parameters'
      else
        {}
      end

      headers
    end

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
      unless user_agent_index.nil?
        user_agent = arr.delete_at(user_agent_index)
        arr.unshift(user_agent)
      end

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
