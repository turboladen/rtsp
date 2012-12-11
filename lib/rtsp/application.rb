require 'sdp/description'
require 'etc'
require 'socket'

require_relative '../ext/time_ext'

require_relative 'abstract_stream'
require_relative 'application_dsl'
require_relative 'error'
require_relative 'logger'
require_relative 'server'
#require_relative 'stream'


module RTSP
  class Application
    include RTSP::ApplicationDSL
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
