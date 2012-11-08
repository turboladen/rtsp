require_relative 'request'
require_relative 'stream_server'
require_relative 'global'
require 'socket'

module RTSP
  SUPPORTED_VERSION = "1.0"

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
  class Server
    extend RTSP::Global

    OPTIONS_LIST = %w(OPTIONS DESCRIBE SETUP TEARDOWN PLAY
     PAUSE GET_PARAMETER SET_PARAMETER)

    attr_accessor :options_list
    attr_accessor :version
    attr_accessor :session
    attr_accessor :agent

    # Initializes the the Stream Server.
    #
    # @param [Fixnum] host IP interface to bind.
    # @param [Fixnum] port RTSP port.
    # @todo Only initialize a TCP or UDP server/socket as needed.
    def initialize(host, port=554)
      @session =  rand(99999999)
      @stream_server = RTSP::StreamServer.instance
      @interface_ip = host
      @stream_server.interface_ip = host
      @tcp_server = TCPServer.new(host, port)
      @udp_server = UDPSocket.new
      @udp_server.bind(host, port)
      @agent = {}
    end

    # Starts accepting TCP connections
    def start
      Thread.start { udp_listen }

      loop do
        client = @tcp_server.accept

        Thread.start do
          begin
            loop { break if serve(client) == -1 }
          rescue EOFError
            # do nothing
          ensure
            client.close unless @agent[client].include? "QuickTime"
          end
        end
      end
    end

    # Listens on the UDP socket for RTSP requests.
    def udp_listen
      loop do
        data, sender = @udp_server.recvfrom(500)
        response = process_request(data, sender[3])
        @udp_server.send(response, 0, sender[3], sender[1])
      end
    end

    # Serves a client request.
    #
    # @param [IO] io Request/response socket object.
    def serve io
      request_str = ""
      count = 0

      begin
        request_str << io.read_nonblock(500)
      rescue Errno::EAGAIN
        return -1 if count > 50
        count += 1
        sleep 0.01
        retry
      end

      response = process_request(request_str, io)
      io.send(response, 0)
    end

    # Process an RTSP request
    #
    # @param [String] request_str RTSP request.
    # @param [String] remote_address IP address of sender.
    # @return [String] Response.
    def process_request(request_str, io)
      remote_address = io.remote_address.ip_address
      /(?<action>.*) rtsp:\/\// =~ request_str
      request = RTSP::Request.new(request_str, remote_address)
      @agent[io] = request.user_agent
      response, body = send(action.downcase.to_sym, request)

      add_headers(request, response, body)
    end

    # Handles the options request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def options(request)
      RTSP::Server.log "Received OPTIONS request from #{request.remote_host}"
      response = []
      response << "Public: #{OPTIONS_LIST.join ','}"
      response << "\r\n"

      [response]
    end

    # Handles the describe request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def describe(request)
      RTSP::Server.log "Received DESCRIBE request from #{request.remote_host}"
      description = @stream_server.description(request.multicast?, request.stream_index)

      [[], description]
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
      RTSP::Server.log "Received SETUP request from #{request.remote_host}"
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
      RTSP::Server.log "Received PLAY request from #{request.remote_host}"
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
      RTSP::Server.log "Received GET_PARAMETER request from #{request.remote_host}"
      " Pending Implementation"

      [[]]
    end

    # Handles the set_parameter request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def set_parameter(request)
      RTSP::Server.log "Received SET_PARAMETER request from #{request.remote_host}"
      " Pending Implementation"

      [[]]
    end

    # Handles the redirect request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def redirect(request)
      RTSP::Server.log "Received REDIRECT request from #{request.remote_host}"
      " Pending Implementation"

      [[]]
    end

    # Handles the teardown request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def teardown(request)
      RTSP::Server.log "Received TEARDOWN request from #{request.remote_host}"
      sid = request.session[:session_id]
      @stream_server.stop_streaming sid

      [[]]
    end

    # Handles a pause request.
    #
    # @param [RTSP::Request] request
    # @return [Array<Array<String>>] Response headers and body.
    def pause(request)
      RTSP::Server.log "Received PAUSE request from #{request.remote_host}"
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
    def method_missing(method_name, *args, &block)
      RTSP::Server.log("Received request for #{method_name} (not implemented)", :warn)

      [[], "Not Implemented"]
    end

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
  end
end
