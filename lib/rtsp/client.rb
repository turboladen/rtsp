require 'socket'
require 'tempfile'
require 'timeout'
require 'rtp/receiver'
require "base64"

require_relative 'transport_parser'
require_relative 'error'
require_relative 'global'
require_relative 'helpers'
require_relative 'message'
require_relative 'response'

module RTSP

  # This is the main interface to an RTSP server.  A client object uses a couple
  # main objects for configuration: an +RTP::Receiver+ and a Connection Struct.
  # Use the capturer to configure how to capture the data which is the RTP
  # stream provided by the RTSP server.  Use the connection object to control
  # the connection to the server.
  #
  # You can initialize your client object using a block:
  #   client = RTSP::Client.new("rtsp://192.168.1.10") do |connection, capturer|
  #     connection.timeout = 5
  #     capturer.rtp_file = File.open("my_file.rtp", "wb")
  #   end
  #
  # ...or, without the block:
  #   client = RTSP::Client.new("rtsp://192.168.1.10")
  #   client.connection.timeout = 5
  #   client.capturer.rtp_file = File.open("my_file.rtp", "wb")
  #
  # After setting up the client object, call RTSP methods, Ruby style:
  #   client.options
  #
  # Remember that, unlike HTTP, RTSP is state-based (and thus the ability to
  # call certain methods depends on calling other methods first).  Your client
  # object tells you the current RTSP state that it's in:
  #   client.options
  #   client.session_state            # => :init
  #   client.describe
  #   client.session_state            # => :init
  #   client.setup(client.media_control_tracks.first)
  #   client.session_state            # => :ready
  #   client.play(client.aggregate_control_track)
  #   client.session_state            # => :playing
  #   client.pause(client.aggregate_control_track)
  #   client.session_state            # => :ready
  #   client.teardown(client.aggregate_control_track)
  #   client.session_state            # => :init
  #
  # To enable/disable logging for clients, class methods:
  #   RTSP::Client.log?           # => true
  #   RTSP::Client.log = false
  # @todo Break Stream out in to its own class.
  class Client
    include RTSP::Helpers
    extend RTSP::Global

    MAX_BYTES_TO_RECEIVE = 3000

    # @return [URI] The URI that points to the RTSP server's resource.
    attr_reader :server_uri
    
    # @return [Fixnum] Also known as the "sequence" number, this starts at 1 and
    #   increments after every request to the server.  It is reset after
    #   calling #teardown.
    attr_reader :cseq

    # @return [Fixnum] A session is only established after calling #setup;
    #   otherwise returns nil.
    attr_reader :session

    # @return [Array<Symbol>] Only populated after calling #options; otherwise
    #   returns nil.  There's no sense in making any other requests than these
    #   since the server doesn't support them.
    attr_reader :supported_methods

    # @return [Struct::Connection]
    attr_accessor :connection

    # Use to get/set an object for capturing received data.
    #
    # @return [RTP::Receiver]
    attr_accessor :capturer

    # @return [Symbol] See {RFC section A.1.}[http://tools.ietf.org/html/rfc2326#page-76]
    attr_reader :session_state

    # Use to configure options for all clients.
    # @see RTSP::Global
    def self.configure
      yield self if block_given?
    end

    # @param [String] server_url URL to the resource to stream.  If no scheme is
    #   given, "rtsp" is assumed.  If no port is given, 554 is assumed.
    # @yield [Struct::Connection, RTP::Receiver]
    # @yieldparam [Struct::Connection] server_url=
    # @yieldparam [Struct::Connection] timeout=
    # @yieldparam [Struct::Connection] socket=
    # @yieldparam [Struct::Connection] do_capture=
    # @yieldparam [Struct::Connection] interleave=
    # @todo Use server_url everywhere; just use URI to ensure the port & rtspu.
    def initialize(server_url=nil)
      Thread.abort_on_exception = true

      unless defined? Struct::Connection
        Struct.new("Connection", :server_url, :timeout, :socket,
          :do_capture, :interleave)
      end

      @connection = Struct::Connection.new
      @capturer   = RTP::Receiver.new

      yield(@connection, @capturer) if block_given?

      @connection.server_url = server_url || @connection.server_url
      @server_uri            = build_resource_uri_from(@connection.server_url)
      @connection.timeout    ||= 30
      @connection.socket     ||= TCPSocket.new(@server_uri.host, @server_uri.port)
      @connection.do_capture ||= true
      @connection.interleave ||= false

      @max_authorization_tries = 3
      @cseq = 1
      reset_state
    end

    # The URL for the RTSP server to talk to can change if multiple servers are
    # involved in delivering content.  This method can be used to change the
    # server to talk to on the fly.
    #
    # @param [String] new_url The new server URL to use to communicate over.
    def server_url=(new_url)
      @server_uri = build_resource_uri_from new_url
    end

    # The user to be used in Basic Authentication
    #
    # @param [String] user
    def server_user=(user)
      @server_uri.user = user
    end

    # The password to be used in Basic Authentication
    #
    # @param [String] password
    def server_password=(password)
      @server_uri.password = password
    end
    
    # Sends the message over the socket.
    #
    # @param [RTSP::Message] message
    # @return [RTSP::Response]
    # @raise [RTSP::Error] If the timeout value is reached and the server hasn't
    #   responded.
    def send_message message
      RTSP::Client.log "Sending #{message.method_type.upcase} to #{message.request_uri}"
      message.to_s.each_line { |line| RTSP::Client.log line.strip }

      begin
        response = Timeout::timeout(@connection.timeout) do
          @connection.socket.send(message.to_s, 0)
          socket_data = @connection.socket.recvfrom MAX_BYTES_TO_RECEIVE

          RTSP::Client.log "Received response:"
          socket_data.first.each_line { |line| RTSP::Client.log line.strip }

          RTSP::Response.new socket_data.first
        end
      rescue Timeout::Error
        raise RTSP::Error, "Request took more than #{@connection.timeout} seconds to send."
      end

      response
    end

    # Sends an OPTIONS message to the server specified by +@server_uri+.  Sets
    # +@supported_methods+ based on the list of supported methods returned in
    # the Public headers.
    #
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    # @see http://tools.ietf.org/html/rfc2326#page-30 RFC 2326, Section 10.1.
    def options(additional_headers={})
      message = RTSP::Message.options(@server_uri.to_s).with_headers({
          cseq: @cseq })
      message.add_headers additional_headers

      request(message) do |response|
        @supported_methods = extract_supported_methods_from response.public
      end
    end

    # Sends the DESCRIBE request, then extracts the SDP description into
    # +@session_description+, extracts the session +@start_time+ and +@stop_time+,
    # +@content_base+, +@media_control_tracks+, and +@aggregate_control_track+.
    #
    # @todo get tracks, IP's, ports, multicast/unicast
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    # @see http://tools.ietf.org/html/rfc2326#page-31 RFC 2326, Section 10.2.
    # @see #media_control_tracks
    # @see #aggregate_control_track
    def describe additional_headers={}
      message = RTSP::Message.describe(@server_uri.to_s).with_headers({
          cseq: @cseq })
      message.add_headers additional_headers

      request(message) do |response|
        @session_description = response.body
        #@session_start_time =   response.body.start_time
        #@session_stop_time =    response.body.stop_time
        @content_base = build_resource_uri_from response.content_base

        @media_control_tracks    = media_control_tracks
        @aggregate_control_track = aggregate_control_track
      end
    end

    # Sends an ANNOUNCE Request to the provided URL.  This method also requires
    # an SDP description to send to the server.
    #
    # @param [String] request_url The URL to post the presentation or media
    #   object to.
    # @param [SDP::Description] description The SDP description to send to the
    #   server.
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    # @see http://tools.ietf.org/html/rfc2326#page-32 RFC 2326, Section 10.3.
    def announce(request_url, description, additional_headers={})
      message = RTSP::Message.announce(request_url).with_headers({ cseq: @cseq })
      message.add_headers additional_headers
      message.body = description.to_s

      request(message)
    end

    # Builds the Transport header fields string based on info used in setting up
    # the Client instance.
    #
    # @return [String] The String to use with the Transport header.
    # @see http://tools.ietf.org/html/rfc2326#page-58 RFC 2326, Section 12.39.
    def request_transport
      value = "RTP/AVP;#{@capturer.ip_addressing_type};client_port="
      value << "#{@capturer.rtp_port}-#{@capturer.rtcp_port}\r\n"
    end

    # Sends the SETUP request, then sets +@session+ to the value returned in the
    # Session header from the server, then sets the +@session_state+ to +:ready+.
    #
    # @todo +@session+ numbers are relevant to tracks, and a client must be able
    #   to play multiple tracks at the same time.
    # @param [String] track
    # @param [Hash] additional_headers
    # @return [RTSP::Response] The response formatted as a Hash.
    # @see http://tools.ietf.org/html/rfc2326#page-33 RFC 2326, Section 10.4.
    def setup(track, additional_headers={})
      message = RTSP::Message.setup(track).with_headers({
          cseq: @cseq, transport: request_transport })
      message.add_headers additional_headers

      request(message) do |response|
        if @session_state == :init
          @session_state = :ready
        end

        @session   = response.session
        parser     = RTSP::TransportParser.new
        @transport = parser.parse(response.transport)

        unless @transport[:transport_protocol].nil?
          @capturer.transport_protocol = @transport[:transport_protocol]
        end

        @capturer.rtp_port = @transport[:client_port][:rtp].to_i
        @capturer.ip_address = @transport[:destination].to_s
      end
    end

    # Sends the PLAY request and sets +@session_state+ to +:playing+.
    #
    # @param [String] track
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    # @todo If playback over UDP doesn't result in any data coming in on the
    #   socket, re-setup with RTP/AVP/TCP;unicast;interleaved=0-1.
    # @raise [RTSP::Error] If +#play+ is called but the session hasn't yet been
    #   set up via +#setup+.
    # @see http://tools.ietf.org/html/rfc2326#page-34 RFC 2326, Section 10.5.
    def play(track, additional_headers={}, &block)
      message = RTSP::Message.play(track).with_headers({
          cseq: @cseq, session: @session[:session_id] })
      message.add_headers additional_headers

      request(message) do
        unless @session_state == :ready
          raise RTSP::Error, "Session not set up yet.  Run #setup first."
        end

        RTSP::Client.log "Capturing RTP data on port #{@transport[:client_port][:rtp]}"
        @capturer.start(&block)
        @session_state = :playing
      end
    end

    # Sends the PAUSE request and sets +@session_state+ to +:ready+.
    #
    # @param [String] track A track or presentation URL to pause.
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    # @see http://tools.ietf.org/html/rfc2326#page-36 RFC 2326, Section 10.6.
    def pause(track, additional_headers={})
      message = RTSP::Message.pause(track).with_headers({
        cseq: @cseq, session: @session[:session_id] })
      message.add_headers additional_headers

      request(message) do
        if [:playing, :recording].include? @session_state
          @session_state = :ready
        end
      end
    end

    # Sends the TEARDOWN request, then resets all state-related instance
    # variables.
    #
    # @param [String] track The presentation or media track to teardown.
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    # @see http://tools.ietf.org/html/rfc2326#page-37 RFC 2326, Section 10.7.
    def teardown(track, additional_headers={})
      message = RTSP::Message.teardown(track).with_headers({
          cseq: @cseq, session: @session[:session_id] })
      message.add_headers additional_headers

      request(message) do
        @capturer.stop
        reset_state
      end
    end

    # Sends the GET_PARAMETERS request.
    #
    # @param [String] track The presentation or media track to ping.
    # @param [String] body The string containing the parameters to send.
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    # @see http://tools.ietf.org/html/rfc2326#page-37 RFC 2326, Section 10.8.
    def get_parameter(track, body="", additional_headers={})
      message = RTSP::Message.get_parameter(track).with_headers({ cseq: @cseq })
      message.add_headers additional_headers
      message.body = body

      request(message)
    end

    # Sends the SET_PARAMETERS request.
    #
    # @param [String] track The presentation or media track to teardown.
    # @param [String] parameters The string containing the parameters to send.
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    # @see http://tools.ietf.org/html/rfc2326#page-38 RFC 2326, Section 10.9.
    def set_parameter(track, parameters, additional_headers={})
      message = RTSP::Message.set_parameter(track).with_headers({ cseq: @cseq })
      message.add_headers additional_headers
      message.body = parameters

      request(message)
    end

    # Sends the RECORD request and sets +@session_state+ to +:recording+.
    #
    # @param [String] track
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    # @see http://tools.ietf.org/html/rfc2326#page-39 RFC 2326, Section 10.11.
    def record(track, additional_headers={})
      message = RTSP::Message.record(track).with_headers({
          cseq: @cseq, session: @session[:session_id] })
      message.add_headers additional_headers

      request(message) { @session_state = :recording }
    end

    # Executes the Request with the arguments passed in, yields the response to
    # the calling block, checks the CSeq response and the session response,
    # then increments +@cseq+ by 1.  Handles any exceptions raised during the
    # Request.
    #
    # @param [RTSP::Message] message
    # @yield [RTSP::Response]
    # @return [RTSP::Response]
    # @raise [RTSP::Error] All 4xx & 5xx response codes & their messages.
    def request message
      response = send_message message
      #compare_sequence_number response.cseq
      @cseq += 1
      if response.code.to_s =~ /2../
        yield response if block_given?
      elsif response.code == 401
        send_authorization(message)
      elsif response.code.to_s =~ /(4|5)../
        if (defined? response.connection) && response.connection == 'Close'
          reset_state
        end

        raise RTSP::Error, "#{response.code}: #{response.message}"
      else
        raise RTSP::Error, "Unknown Response code: #{response.code}"
      end

      dont_ensure_list = [:options, :describe, :teardown, :set_parameter,
          :get_parameter]
      unless dont_ensure_list.include? message.method_type
        ensure_session
      end

      response
    end

    # Extracts the URL associated with the "control" attribute from the main
    # section of the session description.
    #
    # @return [String] The URL as a String.
    def aggregate_control_track
      aggregate_control = @session_description.attributes.find_all do |a|
        a[:attribute] == "control"
      end

      "#{@content_base}#{aggregate_control.first[:value].gsub(/\*/, "")}"
    end

    # Extracts the value of the "control" attribute from all media sections of
    # the session description (SDP).  You have to call the +#describe+ method in
    # order to get the session description info.
    #
    # @return [Array<String>] The tracks made up of the content base + control
    #   track value.
    # @see #describe
    def media_control_tracks
      tracks = []

      if @session_description.nil?
        tracks << ""
      else
        @session_description.media_sections.each do |media_section|
          media_section[:attributes].each do |a|
            tracks << "#{@content_base}#{a[:value]}" if a[:attribute] == "control"
          end
        end
      end

      tracks
    end

    private
    
    # Resends a message with an Authorization header when possible
    # @param [RTSP:Message] message The message that must be repeated with Authorization
    def send_authorization(message)
      if @server_uri.user and @server_uri.password
        credentials = Base64.strict_encode64("#{@server_uri.user}:#{@server_uri.password}")
        headers = { :authorization => "Basic #{credentials}" }
        new_message = RTSP::Message.send(message.method_type.to_sym,@server_uri.to_s).with_headers(headers)
        new_message.add_headers message.headers
        request(new_message)
      end
    end
    
    # Sets state related variables back to their starting values;
    # +@session_state+ is set to +:init+; +@session+ is set to 0.
    def reset_state
      @session_state = :init
      @session = {}
    end

    # Takes the methods returned from the Public header from an OPTIONS response
    # and puts them to an Array.
    #
    # @param [String] method_list The string returned from the server containing
    #   the list of methods it supports.
    # @return [Array<Symbol>] The list of methods as symbols.
    # @see #options
    def extract_supported_methods_from method_list
      method_list.downcase.split(', ').map { |m| m.to_sym }
    end

    # Compares the session number passed in to the current client session
    # number ( +@session+ ) and raises if they're not equal.  If that's the case,
    # the server responded to a different request.
    #
    # @todo Remove this--it's not used.
    # @param [Fixnum] server_session Session number returned by the server.
    # @raise [RTSP::Error] If the server returns a Session value that's different
    #   from what the client sent.
    def compare_session_number server_session
      if @session[:session_id] != server_session
        message = "Session number mismatch.  Client: #{@session[:session_id]}, Server: #{server_session}"
        raise RTSP::Error, message
      end
    end

    # Compares the sequence number passed in to the current client sequence
    # number ( +@cseq+ ) and raises if they're not equal.  If that's the case, the
    # server responded to a different request.
    #
    # @param [Fixnum] server_cseq Sequence number returned by the server.
    # @raise [RTSP::Error] If the server returns a CSeq value that's different
    #   from what the client sent.
    def compare_sequence_number server_cseq
      if @cseq != server_cseq
        message = "Sequence number mismatch.  Client: #{@cseq}, Server: #{server_cseq}"
        raise RTSP::Error, message
      end
    end

    # Ensures that +@session+ is set before continuing on.
    #
    # @raise [RTSP::Error] Raises if @session isn't set.
    def ensure_session
      if @session.empty?
        raise RTSP::Error, "Session number not retrieved from server yet.  Run SETUP first."
      end
    end

  end
end

RTSP::Client.log = false
