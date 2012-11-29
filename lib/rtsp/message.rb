require 'sdp'
require_relative 'error'
require_relative 'global'
require_relative 'helpers'
require_relative 'logger'
require_relative 'transport_parser'
require_relative 'version'
require_relative '../ext/hash_ext'

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

    RTSP_ACCEPT_TYPE = "application/sdp"
    RTSP_DEFAULT_NPT = "0.000-"
    RTSP_DEFAULT_SEQUENCE_NUMBER = 1

    attr_reader :headers
    attr_reader :body
    attr_writer :rtsp_version

    # @param [Symbol] method_type The RTSP method to build and send.
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
    # @param [*] value The value to set the header field to.
    def header(type, value)
      if type.is_a? Symbol
        @headers[type] = value
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

    # Like #with_headers, this allows including a :body key/value pair to add
    # to the message.
    #
    # @param [Hash] new_stuff The headers and body to add to the message.
    # @return [RTSP::Message]
    def with_headers_and_body(new_stuff)
      with_body(new_stuff[:body])
      new_stuff.delete(:body)

      with_headers(new_stuff)

      self
    end

    # Use when creating a new Message to add body you want.  This is really just
    # syntactic sugar for #add_body.
    #
    # @example Simple header
    #   RTSP::Message.options("192.168.1.10").with_body("The body!")
    # @param [Hash] new_body The new body to add to the request.
    def with_body(new_body)
      add_body new_body

      self
    end

    # Adds the body to the message, adds the Content-Length header and sets the
    # value to the length of +new_body+.
    #
    # @param [String] new_body
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

    # Takes the raw request text and splits it into a 2-element Array, where 0
    # is the text containing the headers and 1 is the text containing the body.
    #
    # @param [String] raw_request
    # @return [Array<String>] 2-element Array containing the head and body of
    #   the request.  Body will be nil if there wasn't one in the request.
    def split_head_and_body_from raw_request
      head_and_body = raw_request.split("\r\n\r\n", 2)
      head = head_and_body.first
      body = head_and_body.last == head ? nil : head_and_body.last

      [head, body]
    end

    # Reads through each header line of the RTSP request, extracts the
    # request code, request message, request version, and adds the header
    # name/value pair to @headers.
    #
    # @param [String] head The section of headers from the request text.
    def parse_head head
      @headers ||= {}
      lines = head.split "\r\n"

      lines.each_with_index do |line, i|
        if i == 0
          extract_status_line(line)
          next
        end

        if line.include? "Session: "
          value = {}
          line =~ /Session: (\d+)/
          value[:session_id] = $1.to_i

          if line =~ /timeout=(.+)/
            value[:timeout] = $1.to_i
          end

          @headers[:session] = value
        elsif line.include? "Transport: "
          transport_data = line.match(/\S+$/).to_s
          transport_parser = RTSP::TransportParser.new
          @headers[:transport] = transport_parser.parse(transport_data)
        elsif line.include? ": "
          header_and_value = line.strip.split(":", 2)
          header_name = header_and_value.first.downcase.gsub(/-/, "_").to_sym
          value = header_and_value[1].strip
          @headers[header_name] = Integer(value) rescue value
        end
      end
    end

    # Reads through each line of the RTSP response body and parses it if
    # needed.  Returns a SDP::Description if the Content-Type is
    # 'application/sdp', otherwise returns the String that was passed in.
    #
    # @param [String] body
    def parse_body body
      if body =~ /^(\r\n|\n)/
        body.gsub!(/^(\r\n|\n)/, '')
      end

      @body = if @headers[:content_type] && @headers[:content_type].include?("application/sdp")
        SDP.parse body
      else
        body
      end
    end

    # This custom redefinition of #inspect is needed because of the #to_s
    # definition.
    #
    # @return [String]
    def inspect
      me = "#<#{self.class.name}:0x#{self.object_id.to_s(16)}"

      ivars = self.instance_variables.map do |variable|
        "#{variable}=#{instance_variable_get(variable).inspect}"
      end.join(' ')

      me << " #{ivars} " unless ivars.empty?
      me << ">"

      me
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
      message << @headers.to_headers_s
      message << "\r\n"
      message << "#{@body}" unless @body.empty?

      message
    end

    def status_line
      "This shouldn't get called.  Inheriting classes should redefine this.\r\n"
    end

    # Creates an attr_reader with the name given and sets it to the value
    # that's given.
    #
    # @param [*] values The header values to put to string.
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
      end

      instance_variable_set("@#{name}", value)

      define_singleton_method name.to_sym do
        instance_variable_get "@#{name}".to_sym
      end
    end
  end
end
