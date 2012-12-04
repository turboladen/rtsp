require_relative 'base'


module RTSP
  module Backends
    class TCPServer < Base
      def initialize(host, port)
        @host = host
        @port = port
        super()
      end

      def connect
        @signature = EventMachine.start_server(@host, @port, RTSP::Connection,
          &method(:initialize_connection))
      end

      def close_connection
        EventMachine.stop_server(@signature)
      end

      def location
        "#{@host}:#{@port} (TCP)"
      end
    end
  end
end
