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
  # will  be reassembled in the correct order, as they're written to file
  # (objects of this type don't don't currently check RTP sequence numbers
  # on the data that's been received).
  class Capturer

    # Name of the file the data will be captured to unless #rtp_file is set.
    DEFAULT_CAPFILE_NAME = "rtsp_capture.rtsp"

    # Maximum number of bytes to receive on the socket.
    MAX_BYTES_TO_RECEIVE = 3000

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
    end

    # Initializes a server of the correct socket type.
    #
    # @return [UDPSocket, TCPSocket]
    # @raise [RTSP::Error] If +@transport_protocol was not set to +:UDP+ or
    #   +:TCP+.
    def init_server
      if @transport_protocol == :UDP
        server = init_udp_server
      elsif @transport_protocol == :tcp
        server = init_tcp_server
      else
        raise RTSP::Error, "Unknown streaming_protocol requested: #{@transport_protocol}"
      end

      server
    end

    # Starts capturing data on +@rtp_port+ and writes it to +@rtp_file+.
    def run
      server = init_server

      loop do
        data = server.recvfrom(MAX_BYTES_TO_RECEIVE).first
        RTSP::Client.log data.size
        @rtp_file.write data
      end
    end

    # Sets up to receive data on a UDP socket, using +@rtp_port+.
    #
    # @return [UDPSocket]
    def init_udp_server
      server = UDPSocket.open
      server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEPORT, true)
      server.bind('0.0.0.0', @rtp_port)
      RTSP::Client.log "UDP server setup to receive on port #{@rtp_port}"

      server
    end

    # Sets up to receive data on a TCP socket, using +@rtp_port+.
    #
    # @return [TCPSocket]
    def init_tcp_server
      server = TCPSocket.new('0.0.0.0', @rtp_port)
      server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEPORT, true)
      RTSP::Client.log "TCP server setup to receive on port #{@rtp_port}"

      server
    end
  end
end
