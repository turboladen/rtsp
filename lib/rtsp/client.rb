require 'socket'
require 'tempfile'
require 'timeout'

require_relative 'transport_parser'
require_relative 'capturer'
require_relative 'error'
require_relative 'global'
require_relative 'helpers'
require_relative 'message'
require_relative 'response'

module RTSP

  # Allows for pulling streams from an RTSP server.
  class Client
    include RTSP::Helpers
    extend RTSP::Global

    DEFAULT_CAPFILE_NAME = "ruby_rtsp_capture.rtsp"
    MAX_BYTES_TO_RECEIVE = 3000

    attr_reader :server_uri
    attr_reader :cseq
    attr_reader :session
    attr_reader :supported_methods
    attr_accessor :tracks
    attr_accessor :connection

    # Use to get/set an object for capturing received data.
    # @param [RTSP::Capturer]
    # @return [RTSP::Capturer]
    attr_accessor :capturer

    # @todo Break Stream out in to its own class.
    # See RFC section A.1.
    attr_reader :session_state

    # Use to configure options for all clients.  See RTSP::Global for the options.
    def self.configure
      yield self if block_given?
    end

    # @param [String] server_url URL to the resource to stream.  If no scheme is
    #   given, "rtsp" is assumed.  If no port is given, 554 is assumed.
    # @yield [Struct::Connection, RTSP::Capturer]
    # @yieldparam [Struct::Connection] server_url=
    # @yieldparam [Struct::Connection] timeout=
    # @yieldparam [Struct::Connection] socket=
    # @yieldparam [Struct::Connection] do_capture=
    # @yieldparam [Struct::Connection] interleave=
    # @todo Use server_url everywhere; just use URI to ensure the port & rtspu.
    def initialize(server_url=nil)
      Thread.abort_on_exception = true

      Struct.new("Connection", :server_url, :timeout, :socket,
          :do_capture, :interleave)
      @connection = Struct::Connection.new
      @capturer   = RTSP::Capturer.new

      yield(connection, capturer) if block_given?

      @connection.server_url       = server_url || @connection.server_url
      @server_uri                  = build_resource_uri_from(@connection.server_url)
      @connection.timeout          ||= 30
      @connection.socket           ||= TCPSocket.new(@server_uri.host, @server_uri.port)
      @connection.do_capture       ||= true
      @connection.interleave       ||= false
      @capturer.rtp_port           ||= 9000
      @capturer.transport_protocol ||= :UDP
      @capturer.broadcast_type     ||= :unicast
      @capturer.rtp_file           ||= Tempfile.new(DEFAULT_CAPFILE_NAME)

      @play_thread = nil
      @cseq        = 1
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

    # Sends the message over the socket.
    #
    # @param [RTSP::Message] message
    # @return [RTSP::Response]
    def send_message message
      RTSP::Client.log "Sending #{message.method_type.upcase} to #{message.request_uri}"
      message.to_s.each_line { |line| RTSP::Client.log line.strip }

      begin
        response = Timeout::timeout(@connection.timeout) do
          @connection.socket.send(message.to_s, 0)
          socket_data = @connection.socket.recvfrom MAX_BYTES_TO_RECEIVE
          RTSP::Response.new socket_data.first
        end
      rescue Timeout::Error
        raise RTSP::Error, "Request took more than #{@connection.timeout} seconds to send."
      end

      RTSP::Client.log "Received response:"

      if response
        response.to_s.each_line { |line| RTSP::Client.log line.strip }
      end

      response
    end

    # Sends an OPTIONS message to the server specified by +@server_uri+.  Sets
    # +@supported_methods+ based on the list of supported methods returned in
    # the Public headers.
    #
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
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
    # +@content_base+, media_control_tracks, and aggregate_control_track.
    #
    # @todo get tracks, IP's, ports, multicast/unicast
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
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

    # @param [String] request_url The URL to post the presentation or media
    #   object to.
    # @param [SDP::Description] description The SDP description to send to the
    #   server.
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    def announce(request_url, description, additional_headers={})
      message = RTSP::Message.announce(request_url).with_headers({ cseq: @cseq })
      message.add_headers additional_headers
      message.body = description.to_s

      request(message)
    end

    # Builds the Transport header fields string based on info used in setting up
    # the Client instance.
    #
    # @return [String] The String to use wit the Transport header.
    def request_transport
      value = "RTP/AVP;#{@capturer.broadcast_type};client_port="
      value << "#{@capturer.rtp_port}-#{@capturer.rtp_port + 1}\r\n"
    end

    # Sends the SETUP request, then sets +@session+ to the value returned in the
    # Session header from the server, then sets the +@session_state+ to :ready.
    #
    # @todo +@session+ numbers are relevant to tracks, and a client can play
    #   multiple tracks at the same time.
    # @param [String] track
    # @param [Hash] additional_headers
    # @return [RTSP::Response] The response formatted as a Hash.
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
        @transport = parser.parse response.transport

        unless @transport[:transport_protocol].nil?
          @capturer.transport_protocol = @transport[:transport_protocol]
        end

        @capturer.rtp_port     = @transport[:client_port][:rtp].to_i
        @capturer.broadcast_type = @transport[:broadcast_type]
      end
    end

    # Sends the PLAY request and sets +@session_state+ to :playing.
    #
    # @param [String] track
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    # @todo If playback over UDP doesn't result in any data coming in on the
    #   socket, re-setup with RTP/AVP/TCP;unicast;interleaved=0-1.
    def play(track, additional_headers={})
      message = RTSP::Message.play(track).with_headers({
          cseq: @cseq, session: @session })
      message.add_headers additional_headers

      request(message) do
        unless @session_state == :ready
          raise RTSP::Error, "Session not set up yet.  Run #setup first."
        end

        if @play_thread.nil?
          log "Capturing RTP data on port #{@transport[:client_port][:rtp]}"

          @play_thread = Thread.new do
            @capturer.run
          end
        end

        @session_state = :playing
      end
    end

    # Sends the PAUSE request and sets +@session_state+ to :ready.
    #
    # @param [String] track A track or presentation URL to pause.
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    def pause(track, additional_headers={})
      message = RTSP::Message.pause(track).with_headers({
          cseq: @cseq, session: @session })
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
    def teardown(track, additional_headers={})
      message = RTSP::Message.teardown(track).with_headers({
          cseq: @cseq, session: @session })
      message.add_headers additional_headers

      request(message) do
        reset_state
        if @play_thread
          @capturer.rtp_file.close
          @play_thread.exit
        end
      end
    end

    # Sets state related variables back to their starting values;
    # +@session_state+ is set to +:init+; +@session+ is set to 0.
    def reset_state
      @session_state = :init
      @session       = 0
    end

    # Sends the GET_PARAMETERS request.
    #
    # @param [String] track The presentation or media track to ping.
    # @param [String] body The string containing the parameters to send.
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    def get_parameter(track, body="", additional_headers={})
      message = RTSP::Message.get_parameter(track).with_headers({
          cseq: @cseq })
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
    def set_parameter(track, parameters, additional_headers={})
      message = RTSP::Message.set_parameter(track).with_headers({
          cseq: @cseq })
      message.add_headers additional_headers
      message.body = parameters

      request(message)
    end

    # Sends the RECORD request and sets +@session_state+ to :recording.
    #
    # @param [String] track
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    def record(track, additional_headers={})
      message = RTSP::Message.record(track).with_headers({
          cseq: @cseq, session: @session })
      message.add_headers additional_headers

      request(message) { @session_state = :recording }
    end

    # Executes the Request with the arguments passed in, yields the response to
    # the calling block, checks the CSeq response and the session response,
    # then increments +@cseq+ by 1.  Handles any exceptions raised during the
    # Request.
    #
    # @param [Hash] new_args
    # @yield [RTSP::Response]
    # @return [RTSP::Response]
    def request message
      begin
        response = send_message message
        compare_sequence_number response.cseq
        @cseq += 1

        if response.code.to_s =~ /2../
          yield response if block_given?
        elsif response.code.to_s =~ /(4|5)../
          if (defined? response.connection) && response.connection == 'Close'
            reset_state
          end

          raise RTSP::Error, "#{response.code}: #{response.message}"
        else
          raise RTSP::Error, "Unknown Response code: #{response.code}"
        end

        unless [:options, :describe, :teardown].include? message.method_type
          ensure_session
        end
      rescue RTSP::Error => ex
        RTSP::Client.log "Got exception: #{ex.message}"
        ex.backtrace.each { |b| RTSP::Client.log b }
      end

      response
    end

    # Ensures that +@session+ is set before continuing on.
    #
    # @raise [RTSP::Error] Raises if @session isn't set.
    # @return Returns whatever the block returns.
    def ensure_session
      unless @session > 0
        raise RTSP::Error, "Session number not retrieved from server yet.  Run SETUP first."
      end
    end

    # Extracts the URL associated with the "control" attribute from the main
    # section of the session description.
    #
    # @return [String]
    def aggregate_control_track
      aggregate_control = @session_description.attributes.find_all do |a|
        a[:attribute] == "control"
      end

      "#{@content_base}#{aggregate_control.first[:value].gsub(/\*/, "")}"
    end

    # Extracts the value of the "control" attribute from all media sections of
    # the session description (SDP).  You have to call the #describe method in
    # order to get the session description info.
    #
    # @return [Array<String>] The tracks made up of the content base + control
    # track value.
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

    # Compares the sequence number passed in to the current client sequence
    # number (+@cseq+) and raises if they're not equal.  If that's the case, the
    # server responded to a different request.
    #
    # @param [Fixnum] server_cseq Sequence number returned by the server.
    # @raise [RTSP::Error]
    def compare_sequence_number server_cseq
      if @cseq != server_cseq
        message = "Sequence number mismatch.  Client: #{@cseq}, Server: #{server_cseq}"
        raise RTSP::Error, message
      end
    end

    # Compares the session number passed in to the current client session
    # number (+@session+) and raises if they're not equal.  If that's the case,
    # the server responded to a different request.
    #
    # @param [Fixnum] server_session Session number returned by the server.
    # @raise [RTSP::Error]
    def compare_session_number server_session
      if @session != server_session
        message = "Session number mismatch.  Client: #{@session}, Server: #{server_session}"
        raise RTSP::Error, message
      end
    end

    # Takes the methods returned from the Public header from an OPTIONS response
    # and puts them to an Array.
    #
    # @param [String] method_list The string returned from the server containing
    #   the list of methods it supports.
    # @return [Array<Symbol>] The list of methods as symbols.
    def extract_supported_methods_from method_list
      method_list.downcase.split(', ').map { |m| m.to_sym }
    end
  end
end
