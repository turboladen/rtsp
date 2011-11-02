require 'tempfile'
require 'socket'

require_relative 'error'

module RTSP

  # Objects of this type can be used with a +RTSP::Client+ object in order to
  # capture the RTP data transmitted to the client as a result of an RTSP
  # PLAY call.
  #
  # In this version, objects of this type don't do much other than just capture
  # the data to a file; in later versions, objects of this type will be able
  # to provide a "sink" and allow for ensuring that the received  RTP packets
  # will be reassembled in the correct order, as they're written to file
  # (objects of this type don't don't currently allow for checking RTP sequence
  # numbers on the data that's been received).
  class Capturer

    # Name of the file the data will be captured to unless #rtp_file is set.
    DEFAULT_CAPFILE_NAME = "rtsp_capture.rtsp"

    # Maximum number of bytes to receive on the socket.
    MAX_BYTES_TO_RECEIVE = 3000

    # Maximum times to retry using the next greatest port number.
    MAX_PORT_NUMBER_RETRIES = 50

    # @param [File] rtp_file The file to capture the RTP data to.
    # @return [File]
    attr_accessor :rtp_file

    # @param [Fixnum] rtp_port The port on which to capture the RTP data.
    # @return [Fixnum]
    attr_accessor :rtp_port

    # @param [Symbol] transport_protocol +:UDP+ or +:TCP+.
    # @return [Symbol]
    attr_accessor :transport_protocol

    # @param [Symbol] broadcast_type +:multicast+ or +:unicast+.
    # @return [Symbol]
    attr_accessor :broadcast_type

    # @param [Symbol] transport_protocol The type of socket to use for capturing
    #   the data. +:UDP+ or +:TCP+.
    # @param [Fixnum] rtp_port The port on which to capture RTP data.
    # @param [File] capture_file The file object to capture the RTP data to.
    def initialize(transport_protocol=:UDP, rtp_port=9000, rtp_capture_file=nil)
      @transport_protocol = transport_protocol
      @rtp_port = rtp_port
      @rtp_file = rtp_capture_file || Tempfile.new(DEFAULT_CAPFILE_NAME)
      @listener = nil
      @file_builder = nil
      @queue = Queue.new
    end

    # Initializes a server of the correct socket type.
    #
    # @return [UDPSocket, TCPSocket]
    # @raise [RTSP::Error] If +@transport_protocol was not set to +:UDP+ or
    #   +:TCP+.
    def init_server(protocol, port=9000)
      if protocol == :UDP
        server = init_udp_server(port)
      elsif protocol == :TCP
        server = init_tcp_server(port)
      else
        raise RTSP::Error, "Unknown streaming_protocol requested: #{@transport_protocol}"
      end

      server
    end

    # Simply calls #start_file_builder and #start_listener.
    def run
      log "Starting #{self.class} on port #{@rtp_port}..."

      start_file_builder
      start_listener
    end

    # Starts the +@file_builder+ thread that pops data off of the Queue that
    # #start_listener pushed data on to.  It then takes that data and writes it
    # to +@rtp_file+.
    def start_file_builder
      return @file_builder if @file_builder and @file_builder.alive?

      @file_builder = Thread.start(@rtp_file) do |rtp_file|
        loop do
          rtp_file.write @queue.pop until @queue.empty?
        end
      end

      @file_builder.abort_on_exception = true
    end

    # Starts the +@listener+ thread that starts up the server, then takes the
    # data received from the server and pushes it on to the +@queue+ so
    # the +@file_builder+ thread can deal with it.
    def start_listener
      return @listener if @listener and @listener.alive?


      @listener = Thread.start do
        server = init_server(@transport_protocol, @rtp_port)

        loop do
          data = server.recvfrom(MAX_BYTES_TO_RECEIVE).first
          log "received data with size: #{data.size}"
          @queue << data
        end
      end

      @listener.abort_on_exception = true
    end

    # @return [Boolean] true if the +@listener+ thread is running; false if not.
    def listening?
      if @listener then @listener.alive? else false end
    end

    # @return [Boolean] true if the +@file_builder+ thread is running; false if
    #   not.
    def file_building?
      if @file_builder then @file_builder.alive? else false end
    end

    # Returns if the #run loop is in action.
    #
    # @return [Boolean] true if the run loop is running.
    def running?
      listening? || file_building?
    end

    # Breaks out of the run loop.
    def stop
      log "Stopping #{self.class} on port #{@rtp_port}..."
      stop_listener
      log "listening? #{listening?}"
      stop_file_builder
      log "file building? #{file_building?}"
      log "running? #{running?}"
      @queue = Queue.new
    end

    # Kills the +@listener+ thread and sets the variable to nil.
    def stop_listener
      @listener.kill if @listener
      @listener = nil
    end

    # Kills the +@file_builder+ thread and sets the variable to nil.
    def stop_file_builder
      @file_builder.kill if @file_builder
      @file_builder = nil
    end

    # Sets up to receive data on a UDP socket, using +@rtp_port+.
    #
    # @param [Fixnum] port Port number to listen for RTP data on.
    # @return [UDPSocket]
    def init_udp_server(port)
      port_retries = 0

      begin
        server = UDPSocket.open
        server.bind('0.0.0.0', port)
      rescue Errno::EADDRINUSE
        log "RTP port #{port} in use, trying #{port + 1}..."
        port += 1
        port_retries += 1
        retry until port_retries == MAX_PORT_NUMBER_RETRIES + 1
        port = 9000
        raise
      end

      @rtp_port = port
      log "UDP server setup to receive on port #{@rtp_port}"

      server
    end

    # Sets up to receive data on a TCP socket, using +@rtp_port+.
    #
    # @param [Fixnum] port Port number to listen for RTP data on.
    # @return [TCPSocket]
    def init_tcp_server(port)
      port_retries = 0

      begin
        server = TCPServer.new(port)
      rescue Errno::EADDRINUSE
        log "RTP port #{port} in use, trying #{port + 1}..."
        port += 1
        port_retries += 1
        retry until port_retries == MAX_PORT_NUMBER_RETRIES + 1
        port = 9000
        raise
      end

      @rtp_port = port
      log "TCP server setup to receive on port #{@rtp_port}"

      server
    end

    # PRIVATES!
    private

    # Quick wrapper for when not using RTSP::Client (i.e. during tests).
    #
    # @param [String] message The String to log.
    def log(message)
      if defined? RTSP::Client
        RTSP::Client.log "<#{self.class}> #{message}"
      end
    end
  end
end
