require 'socket'
require 'timeout'

require File.expand_path(File.dirname(__FILE__) + '/exception')

module RTSP
  class Capturer

    MAX_PACKET_BYTES= 1500

    def initialize(socket_type, port, save_to_file=false)
      puts "port: #{port}"

      if socket_type == :udp
        @capture_socket = UDPSocket.new
        @capture_socket.bind("0.0.0.0", port)
      #elsif socket_type == :tcp
      #  @capture_socket = TCPSocket.new(host, port)
      else
        raise RTSP::Exception, "Invalid socket type: #{socket_type}"
      end

      @save_to_file = save_to_file

      #while data = @capture_socket.recvfrom(MAX_PACKET_BYTES).first
      #  puts data
      #end
    end

    def start
      @capture_thread = Thread.start(@capture_socket) do |capture|
        data = capture.recvfrom(MAX_PACKET_BYTES)
        puts data
      end
    end

    def stop
      @capture_thread.join
    end
  end
end