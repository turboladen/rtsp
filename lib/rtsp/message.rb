require File.expand_path(File.dirname(__FILE__) + '/helpers')
require File.expand_path(File.dirname(__FILE__) + '/exception')

module RTSP
  class Message
    include RTSP::Helpers

    RTSP_ACCEPT_TYPE = "application/sdp"
    RTSP_DEFAULT_NPT = "0.000-"
    RTSP_DEFAULT_SEQUENCE_NUMBER = 1
    RTP_DEFAULT_CLIENT_PORT = 9000
    RTP_DEFAULT_PACKET_TYPE = "RTP/AVP"
    RTP_DEFAULT_ROUTING = "unicast"
    USER_AGENT = "RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})"

    attr_reader :headers
    attr_reader :body
    attr_writer :rtsp_version

    # @param [Symbol] :method_type The RTSP method to build and send.
    # @param [String] request_uri The URL to communicate to.
    def initialize(method_type, request_uri, &block)
      @method = method_type
      @request_uri = build_resource_uri_from request_uri
      @headers = default_headers
      @body = ""
      @version = DEFAULT_VERSION

      self.instance_eval &block if block_given?

      to_s
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

    # @param [String] value Content to send as the body of the message.
    # Generally this will be a String of some sort, but could be binary data as
    # well.
    def body value
      headers[:content_length] = value.length
      @body = value
    end

    def to_s
      message.to_s
    end

    ###########################################################################
    # PRIVATES
    private

    def message
      message = "#{@method.to_s.upcase} #{@request_uri} RTSP/#{@version}\r\n"
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

      case @method
      when :describe
        headers[:accept] = RTSP_ACCEPT_TYPE
      when :announce
        headers[:content_type] = RTSP_ACCEPT_TYPE
      when :setup
        transport = "#{RTP_DEFAULT_PACKET_TYPE};"
        transport << "#{RTP_DEFAULT_ROUTING};"
        transport << "client_port=#{RTP_DEFAULT_CLIENT_PORT}-#{RTP_DEFAULT_CLIENT_PORT + 1}"

        headers[:transport] = transport
      when :play
        headers[:range] = "npt=#{RTSP_DEFAULT_NPT}"
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