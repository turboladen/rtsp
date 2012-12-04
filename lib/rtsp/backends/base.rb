require 'socket'
require 'eventmachine'
require_relative '../logger'
require_relative '../connection'


module RTSP
  module Backends
    class Base
      include LogSwitch::Mixin

      attr_accessor :server

      def initialize
        #@sessions = {}
        @connections = []

      end

      # Starts accepting TCP connections
      def start
        @stopping = false
        starter = proc do
          connect
          @running = true
        end

        if EventMachine.reactor_running?
          starter.call
        else
          EventMachine.run(&starter)
        end
      end

      protected

      def initialize_connection(connection)
        connection.app = @server.app
        @connections << connection
      end
    end
  end
end
