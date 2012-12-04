require 'sdp/description'
require 'etc'
require 'socket'

require_relative '../ext/time_ext'

require_relative 'abstract_stream'
require_relative 'error'
require_relative 'logger'
require_relative 'server'
#require_relative 'stream'


module RTSP
  class Application
    include LogSwitch::Mixin

    # The SDP description that describes all of the streams.  Per the RFC
    # definition:
    #   A presentation description contains information about one or more media
    #   streams within a presentation, such as the set of encodings, network
    #   addresses and information about the content.
    attr_reader :description

    attr_accessor :session
    #attr_accessor :app


=begin
  # Provides for serving an RTSP stream.  Currently the only method for sourcing
  # streams is via {http://www.dest-unreach.org/socat/ socat}.  It is also only
  # able to source a single media stream.
  # All you need is the multicast source RTP host and port.
  #
  # require 'rtsp/server'
  # server = RTSP::Server.new "10.221.222.90", 8554
  #
  # This is for the stream at index 1 (rtsp://10.221.222.90:8554/stream1)
  # RTSP::StreamServer.instance.source_ip << "239.221.222.241"
  # RTSP::StreamServer.instance.source_port << 6780
  # RTSP::StreamServer.instance.fmtp << "96 packetization-mode=1..."
  # RTSP::StreamServer.instance.rtp_map << "96 H264/90000"
  #
  # This is for the stream at index 2 (rtsp://10.221.222.90:8554/stream2)
  # RTSP::StreamServer.instance.source_ip << "239.221.222.141"
  # RTSP::StreamServer.instance.source_port << 6740
  # RTSP::StreamServer.instance.fmtp << "96 packetization-mode=1..."
  # RTSP::StreamServer.instance.rtp_map << "96 MP4/90000"
  #
  # Now start the server
  # server.start
    def initialize
      @session =  rand(99999999)
      #@stream_server = RTSP::StreamServer.instance
      @interface_ip = host
      #@stream_server.interface_ip = host
      @tcp_server = TCPServer.new(host, port)
      @udp_server = UDPSocket.new
      @udp_server.bind(host, port)
      @agent = {}

      @sessions = {}

      # { '/stream1' => stream_object, '/stream2' => different_stream_object }
      @stream_list = {}

      @supported_methods = OPTIONS_LIST
      Struct.new("Session", :id, :cseq, :remote_address, :remote_port, :stream,
        :user_agent)
=end

    def self.inherited(subclass)

    end

      def self.stream(path)
        puts "stream path: #{path}"
        klass = create_stream_class(path)

        yield klass

        @stream_types ||= {}
        @stream_types[path] = klass
        @description ||= default_description
        @description.media_sections << klass.description
        RTSP::Logger.log "Updated description: #{@description}"
        add_routes_for(path)
      end

      def self.add_routes_for(stream)
        add_route(:options)
        add_route(:describe, stream)
      end

      def self.add_route(verb, stream=nil)
        @routes ||= {}
        @routes[verb.to_sym] = stream
      end

      def self.supported_methods
        @routes.keys.map { |verb| verb.to_s.upcase }
      end

      def self.create_stream_class(path)
        Class.new(::RTSP::AbstractStream) do
          def initialize
            super()
            @path = path
          end
        end
      end

    # Handles the options request.
    #
    # @param [String] client_hostname
    # @return [RTSP::Response] Response headers and body.
    def self.options(env)
      RTSP::Response.new(200).with_headers({
        'CSeq' => env['RTSP_CSEQ'],
        'Public' => self.supported_methods.join(', ')
      })
    end

    def self.describe(env)
      if env['RTSP_ACCEPT'] &&
        env['RTSP_ACCEPT'].match(/application\/sdp/)
        content_type = 'application/sdp'
      else
        RTSP::Logger.log "Unknown Accept types: #{env['RTSP_ACCEPT']}", :warn
        return RTSP::Response.new(451).with_headers('CSeq' => env['RTSP_CSEQ'])
      end

      p @description[:session_section].delete_if { |k, v| v.nil? || v.to_s.empty? }
=begin
      unless @description.valid?
        raise "Incomplete or erroneous description: #{@description.errors}"
      end
=end

      RTSP::Response.new(200).with_headers_and_body({
        'CSeq' => env['RTSP_CSEQ'],
        'Content-Type' => content_type,
        'Content-Base' => env['PATH_INFO'],
        body: @description.to_s
      })
    end

    def self.setup_rtp_sender(type)
      case type
      when :socat
        @rtp_sender = RTP::Sender.instance
        @rtp_sender.stream_module = RTP::Senders::Socat

        yield @rtp_sender if block_given?

=begin
      when :indirection
        # Get remote server's URL
        server_url = yield()

        # Get description from the remote RTSP server
        require_relative 'client'
        client = RTSP::Client.new(server_url)
        response = client.describe
        @description = response.body

        # Get the control URL for the main remote presentation and set that for
        # this URL
        control = @description.attributes.find { |a| a[:attribute] == "control" }
        self.url = control[:value]

        # Get the control URL for the first media section so we can get the
        # Stream object that was setup in configuration.
        media_control =
          @description.media_sections.first[:attributes].find { |a| a[:attribute] == "control" }
        redirected_stream = stream_at(media_control[:value])

        # Create a socket to redirect the RTP data that we'll start receiving.
        redirected_socket = UDPSocket.new
        redirected_socket.bind('0.0.0.0', redirected_stream.client_rtp_port)
        client.capturer.rtp_file = redirected_socket

        # Setup
        media_track = client.media_control_tracks.first
        aggregate_track = client.aggregate_control_track
        client.setup media_track
        client.play aggregate_track
=end
      end
    end

    def self.run!
      app = new

      RTSP::Server.start('0.0.0.0', 5554) do
        run app
      end
    end

    def call(env)
      request_method = env['REQUEST_METHOD'].downcase.to_sym

      RTSP::Logger.log "Received #{request_method} request from #{env['rtsp.remote_address']}:#{env['remote_port']}"

      self.class.send(request_method, env).rack_response
    end

    private

    # @return [SDP::Description]
    def self.default_description
      sdp = SDP::Description.new
      sdp.username = Etc.getlogin
      sdp.id = Time.now.to_ntp
      sdp.version = sdp.id
      sdp.network_type = "IN"
      sdp.address_type = "IP4"

      sdp.unicast_address = UDPSocket.open do |s|
        s.connect('64.233.187.99', 1); s.addr.last
      end

      sdp.name = "Ruby RTSP Stream"
      sdp.information = "This is a Ruby RTSP stream"
      sdp.connection_network_type = "IN"
      sdp.connection_address_type = "IP4"
      sdp.connection_address = sdp.unicast_address
      sdp.start_time = 0
      sdp.stop_time = 0

      sdp.attributes << { tool: "RubyRTSP #{RTSP::VERSION}" }
      sdp.attributes << { control: "*" }
      # User must still define media section.

      sdp
    end
=begin
    # Handles the describe request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
=begin
    def describe(request)
      log "Received DESCRIBE request from #{request.remote_host}"
      description = @stream_server.description(request.multicast?, request.stream_index)

      [[], description]
    end
    def describe(session, request)
      log "Received DESCRIBE request from #{session.remote_address}"

      if request.headers[:accept] && request.headers[:accept].match(/application\/sdp/)
        content_type = 'application/sdp'
      else
        log "Unknown Accept types: #{request.headers[:accept]}", :warn
        return RTSP::Response.new(451).with_headers('CSeq' => session.cseq).to_s
      end

      p request
      p request.uri
      p @stream_list
      RTSP::Response.new(200).with_headers_and_body({
        'CSeq' => session.cseq,
        'Content-Type' => content_type,
        'Content-Base' => request.uri,
        body: @stream_list[request.uri].description
      }).to_s
    end

    # Handles the announce request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def announce(request)
      []
    end

    # Handles the setup request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def setup(request)
      log "Received SETUP request from #{request.remote_host}"
      @session = @session.next
      server_port = @stream_server.setup_streamer(@session,
        request.transport_url, request.stream_index)
      response = []
      transport = generate_transport(request, server_port)
      response << "Transport: #{transport.join}"
      response << "Session: #{@session}"
      response << "\r\n"

      [response]
    end

    # Handles the play request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def play(request)
      log "Received PLAY request from #{request.remote_host}"
      sid = request.session[:session_id]
      response = []
      response << "Session: #{sid}"
      response << "Range: #{request.range}"
      index = request.stream_index - 1
      rtp_sequence, rtp_timestamp = @stream_server.parse_sequence_number(
        @stream_server.source_ip[index], @stream_server.source_port[index])
      @stream_server.start_streaming sid
      response << "RTP-Info: url=#{request.url}/track1;" +
        "seq=#{rtp_sequence + 6} ;rtptime=#{rtp_timestamp}"
      response << "\r\n"

      [response]
    end

    # Handles the get_parameter request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def get_parameter(request)
      log "Received GET_PARAMETER request from #{request.remote_host}"
      " Pending Implementation"

      [[]]
    end

    # Handles the set_parameter request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def set_parameter(request)
      log "Received SET_PARAMETER request from #{request.remote_host}"
      " Pending Implementation"

      [[]]
    end

    # Handles the redirect request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def redirect(request)
      log "Received REDIRECT request from #{request.remote_host}"
      " Pending Implementation"

      [[]]
    end

    # Handles the teardown request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def teardown(request)
      log "Received TEARDOWN request from #{request.remote_host}"
      sid = request.session[:session_id]
      @stream_server.stop_streaming sid

      [[]]
    end

    # Handles a pause request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def pause(request)
      log "Received PAUSE request from #{request.remote_host}"
      response = []
      sid = request.session[:session_id]
      response << "Session: #{sid}"
      @stream_server.disconnect sid

      [response]
    end

    # Adds the headers to the response.
    #
    # @param [RTSP::Request] request
    # @param [Array<String>] response Response headers
    # @param [String] body Response body
    # @param [String] status Response status
    # @return [Array<Array<String>>] Response headers and body.
    def add_headers(request, response, body, status="200 OK")
      result = []
      version ||= SUPPORTED_VERSION
      result << "RTSP/#{version} #{status}"
      result << "CSeq: #{request.cseq}"

      unless body.nil?
        result << "Content-Type: #{request.accept}"
        result << "Content-Base: #{request.url}/"
        result << "Content-Length: #{body.size}"
      end

      result << "Date: #{Time.now.gmtime.strftime('%a, %b %d %Y %H:%M:%S GMT')}"
      result << response.join("\r\n") unless response.nil?
      result << body unless body.nil?

      result.flatten.join "\r\n"
    end

    # Handles unsupported RTSP requests.
    #
    # @param [Symbol] method_name Method name to be called.
    # @param [Array] args Arguments to be passed in to the method.
    # @param [Proc] block A block of code to be passed to a method.
    #def method_missing(method_name, *args, &block)
    #  log("Received request for #{method_name} (not implemented)", :warn)

    #  [[], "Not Implemented"]
    #end



    private

    # Generates the transport headers for the response.
    #
    # @param [RTSP::Request] Request object.
    # @param [Fixnum] server_port Port on which the stream_server is streaming from.
    def generate_transport request, server_port
      port_specifier = request.transport.include?("unicast") ? "client_port" : "port"
      transport = request.transport.split(port_specifier)
      transport[0] << "destination=#{request.remote_host};"
      transport[0] << "source=#{@stream_server.interface_ip};"
      transport[1] = port_specifier + transport[1]
      transport[1] << ";server_port=#{server_port}-#{server_port+1}"

      transport
    end
=end
  end
end
