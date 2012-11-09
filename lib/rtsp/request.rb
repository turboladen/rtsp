require_relative 'message'

module RTSP

  # Parses raw request data from the server/client and turns it into
  # attr_readers.
  class Request < Message

    @method_types = [
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

    @method_types.each do |message_type|
      define_singleton_method message_type do |request_uri|
        self.new(message_type, request_uri)
      end
    end

    # TODO: define #describe somewhere so I can actually test that method.
    class << self

      # Lists the method/message types this class can create.
      # @return [Array<Symbol>]
      attr_accessor :method_types
    end

    # @param [String] raw_request The raw request data received on the socket.
    # @param [Socket::UDPSource] udp_source
    def self.parse(raw_request)
      if raw_request.nil? || raw_request.empty?
        raise RTSP::Error,
          "#{self.class} received nil or empty string--this shouldn't happen."
      end

      /^(?<method_type>\w+)/ =~ raw_request

      new(method_type.downcase.to_sym) do |new_request|
        head, body = new_request.split_head_and_body_from(raw_request)
        new_request.parse_head(head)

        unless body.empty?
          new_request.instance_variable_set(:@raw, raw_request)
          new_request.parse_body(body)
        end

        new_request
      end
    end

    attr_reader :request_uri
    attr_reader :method_type

    # @param [Symbol] method_type The RTSP method to build and send.
    # @param [String] request_uri The URL to include in the message.
    def initialize(method_type, request_uri="")
      @method_type = method_type

      @request_uri = if request_uri.empty? || request_uri == "*"
        request_uri
      else
        build_resource_uri_from(request_uri)
      end

      super()

      yield self if block_given?
    end

    # Pulls out the RTSP version, request code, and request message (AKA the
    # status line info) into instance variables.
    #
    # @param [String] line The String containing the status line info.
    def extract_status_line(line)
      /RTSP\/(?<rtsp_version>\d\.\d)/ =~ line
      /(?<request_uri>rtspu?:\/\/.*) RTSP/ =~ line
      /rtsp:\/\/.*stream(?<stream_index>\d*)m?\/?.* RTSP/ =~ line
      @rtsp_version = rtsp_version
      @request_uri = request_uri

      #create_reader("stream_index", stream_index)
      #@stream_index = stream_index.to_i

      if rtsp_version.nil?
        raise RTSP::Error, "Status line corrupted: #{line}"
      end
    end

    def status_line
      "#{@method_type.to_s.upcase} #{@request_uri} RTSP/#{@rtsp_version}\r\n"
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

    # Returns the transport URL.
    #
    # @return [String] Transport URL associated with the request.
    def transport_url
      /client_port=(?<port>.*)-/ =~ transport

      if port.nil?
        log("Could not find client port associated with transport", :warn)
      else
        "#{@remote_host}:#{port}"
      end
    end

    # Checks if the request is for a multicast stream.
    #
    # @return [Boolean] true if the request is for a multicast stream.
    def multicast?
      return false if @url.nil?

      @url.end_with? "m"
    end
  end
end
