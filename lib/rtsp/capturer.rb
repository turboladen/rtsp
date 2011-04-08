require_relative 'exception'
require 'tempfile'
require 'socket'

module RTSP
  class Capturer
    DEFAULT_CAPFILE_NAME = "rtsp_capture.rtsp"

    attr_accessor :media_file
    attr_accessor :port
    attr_accessor :protocol
    attr_accessor :broadcast_type

    # @param [Symbol] protocol :udp or :tcp
    def initialize(protocol=:udp, rtp_port=9000, capture_file=nil)
      if protocol == :udp
        init_udp_server(rtp_port)
      elsif protocol == :tcp
        init_tcp_server(rtp_port)
      else
        raise RTSP::Exception
      end

      @capture_file = capture_file || Tempfile.new(DEFAULT_CAPFILE_NAME)
    end

    def run
      loop do
        data = @server.recvfrom(MAX_BYTES_TO_RECEIVE).first
        puts data.size
        @capture_file.write data
      end
    end

    def init_udp_server(rtp_port)
      @server = UDPSocket.open
      #opt = [1].pack("i")
      #@server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, opt)
      @server.bind('0.0.0.0', rtp_port)
    end

    def init_tcp_server(rtp_port)
      @server = TCPSocket.new('0.0.0.0', rtp_port)
    end
  end
end
