require_relative 'helpers'
require_relative 'error'
require_relative 'common'
require_relative 'global'
require_relative 'version'

module RTSP

  # This class is responsible for building a single RTSP message that can be
  # used by both clients and servers.
  #
  # Only message types defined in {RFC 2326}[http://tools.ietf.org/html/rfc2326]
  # are implemented, however if you need to add a new message type (perhaps for
  # some custom server implementation?), you can simply add to the supported
  # list by:
  #    RTSP::Message.method_types << :barrel_roll
  #
  # You can then build it like a standard message:
  #   message = RTSP::Message.barrel_roll("192.168.1.10").with_headers({
  #   cseq: 123, content_type: "video/x-m4v" })
  class Message
    extend RTSP::Global
    include RTSP::Helpers
    include RTSP::Common

    RTSP_ACCEPT_TYPE = "application/sdp"
    RTSP_DEFAULT_NPT             = "0.000-"
    RTSP_DEFAULT_SEQUENCE_NUMBER = 1
    USER_AGENT                   =
        "RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})"

    attr_reader :headers
    attr_reader :body
    attr_reader :rtsp_version
    attr_reader :raw

    # @param [Symbol] method_type The RTSP method to build and send.
    # @param [String] request_uri The URL to include in the message.
    def initialize
      @headers     = default_headers
      @body        = ""
      @rtsp_version     = DEFAULT_VERSION
    end

    # Adds the header and its value to the list of headers for the message.
    #
    # @param [Symbol] type The header type.
    # @param [] value The value to set the header field to.
    def header(type, value)
      if type.is_a? Symbol
        headers[type] = value
      else
        raise RTSP::Error, "Header type must be a Symbol (i.e. :cseq)."
      end
    end

    # Use to message-chain with one of the method types; used when creating a
    # new Message to add headers you want.
    #
    # @example Simple header
    #   RTSP::Message.options("192.168.1.10").with_headers({ cseq: @cseq })
    # @example Multi-word header
    #   RTSP::Message.options("192.168.1.10").with_headers({ user_agent:
    #   'My RTSP Client 1.0' })   # => "OPTIONS 192.168.1.10 RTSP 1.0\r\n
    #                             #     CSeq: 1\r\n
    #                             #     User-Agent: My RTSP Client 1.0\r\n"
    # @param [Hash] new_headers The headers to add to the Request.  The Hash
    #   key of each will be converted from snake_case to Rtsp-Style.
    # @return [RTSP::Message]
    def with_headers(new_headers)
      add_headers new_headers

      self
    end

    def add_headers(new_headers)
      @headers.merge! new_headers
    end

    # Use when creating a new Message to add body you want.
    #
    # @example Simple header
    #   RTSP::Message.options("192.168.1.10").with_body("The body!")
    # @param [Hash] new_headers The headers to add to the Request.  The Hash
    #   key will be capitalized; if
    def with_body(new_body)
      add_body new_body

      self
    end

    def add_body new_body
      add_headers({ content_length: new_body.length })
      @body = new_body
    end

    # @param [String] value Content to send as the body of the message.
    #   Generally this will be a String of some sort, but could be binary data as
    #   well. Also, this adds the Content-Length header to the header list.
    def body= value
      add_body value
    end

    # @return [String] The message as a String.
    def to_s
      return @raw if @raw

      message.to_s
    end

    protected

    def default_headers
      {}
    end

    ###########################################################################
    # PRIVATES
    private

    # Builds the request message to send to the server/client.
    #
    # @return [String]
    def message
      message = status_line
      message << headers_to_s(@headers)
      message << "\r\n"
      message << "#{@body}" unless @body.nil?

      #message.each_line { |line| RTSP::Client.log line.strip }

      message
    end

    def status_line
      raise "This shouldn't get called.  Please define this method in your child class."
    end

    # Turns headers from Hash(es) into a String, where each element
    # is a String in the form: [Header Type]: value(s)\r\n.
    #
    # @param [Hash] headers The headers to put to string.
    # @return [String]
    def headers_to_s headers
      header_string = headers.inject("") do |result, (key, value)|
        header_name = key.to_s.split(/_/).map do |header|
          header.capitalize
        end.join('-')

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
    # @param [String] separator The character to use to separate multiple
    #   values that define a header.
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
