require_relative 'socat_streaming'
require 'singleton'

module RTSP
  class StreamServer
    include Singleton
    include SocatStreaming

    def initialize
      @stream_module = SocatStreaming
      @sessions = {}
      @pids = {}
      @rtcp_threads = {}
      @rtp_timestamp = 2892263317
      @rtp_sequence = 53719
    end

    # Sets the stream module to be used by the stream server.
    #
    # @param [Module] Module name.
    def stream_module= module_name
      @stream_module = module_name
      self.class.send(:include, module_name)
    end

    # Gets the current stream_module
    #
    # @return [Module] Module name.
    def stream_module
      @stream_module
    end
  end
end