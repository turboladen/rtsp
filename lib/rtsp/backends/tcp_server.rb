require_relative 'base'


module RTSP
  module Backends
    class TCPServer < Base
      SCHEME = 'rtsp'

      def initialize(host, port)
        @host = host
        @port = port
        super()
      end

      def connect
        @signature = EventMachine.start_server(@host, @port, RTSP::Connection,
          @host, @port, &method(:initialize_connection))
      end

      def close_connection
        EventMachine.stop_server(@signature)
      end

      def location
        "#{SCHEME}://#{@host}:#{@port}"
      end
    end
  end
end
