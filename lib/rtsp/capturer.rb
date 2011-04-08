require_relative 'exception'
require 'tempfile'
require 'socket'

module RTSP
  class Capturer
    DEFAULT_CAPFILE_NAME = "rtsp_capture.rtsp"
    MAX_BYTES_TO_RECEIVE = 3000

    attr_accessor :media_file
    attr_accessor :media_port
    attr_accessor :transport_protocol
    attr_accessor :broadcast_type

    # @param [Symbol] protocol :udp or :tcp
    def initialize(transport_protocol=:udp, rtp_port=9000, capture_file=nil)
      @transport_protocol = transport_protocol
      @media_port = rtp_port
      @media_file = capture_file || Tempfile.new(DEFAULT_CAPFILE_NAME)
    end

    def run
      if @transport_protocol == :udp
        server = init_udp_server
      elsif @transport_protocol == :tcp
        server = init_tcp_server
      else
        raise RTSP::Exception, "Unknown streaming_protocol requested: #{@transport_protocol}"
      end

      loop do
        data = server.recvfrom(MAX_BYTES_TO_RECEIVE).first
        puts data.size
        @media_file.write data
      end
    end

    def init_udp_server
      server = UDPSocket.open
      #opt = [1].pack("i")
      #@server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, opt)
      server.bind('0.0.0.0', @media_port)
      RTSP::Client.log "UDP server setup to receive on port #{@media_port}"

      server
    end

    def init_tcp_server
      server = TCPSocket.new('0.0.0.0', @media_port)
    end
  end
end
