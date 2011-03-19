require 'socket'
require 'timeout'
require 'uri'

require File.expand_path(File.dirname(__FILE__) + '/response')
require File.expand_path(File.dirname(__FILE__) + '/exception')
require File.expand_path(File.dirname(__FILE__) + '/helpers')
require File.expand_path(File.dirname(__FILE__) + '/version')

module RTSP

  # This class allows for building and sending the request message strings that
  # make up RTSP methods.  Clients and Servers use these for building and sending
  # the request messages to communicate in RTSP.
  class Request
    include RTSP::Helpers

    RTSP_DEFAULT_LANGUAGE = "en-US"
    MAX_BYTES_TO_RECEIVE = 3000
    DEFAULT_TIMEOUT = 30

    # Creates an instance of an RTSP::Request object and sends the message
    # over the socket.
    #
    # @param [Hash] args
    # @return [RTSP::Response]
    def self.execute args
      new(args).execute
    end

    # Required arguments:
    # * :method
    # * :resource_url
    # Optional arguments:
    # * :body
    # * :timeout
    # * :socket
    # * :headers
    #
    # @param [Hash] args
    # @option args [Fixnum] :timeout Number of seconds to timeout after trying
    # to send the message of the socket.  Defaults to 2.
    # @option args [Socket] :socket Optional; socket to use to communicate over.
    def initialize(message, args={})
      @message = message.to_s
      @timeout = args[:timeout] || DEFAULT_TIMEOUT

      # TODO: if URI scheme = rtspu, use UDPSocket
      @socket = args[:socket] || TCPSocket.new(@resource_uri.host, @resource_uri.port)
    end

    # @return [RTSP::Response]
    def execute
      RTSP::Client.log "Sending #{@method.to_s.upcase} to #{@resource_uri}"
      response = send_message
      RTSP::Client.log "Received response:"

      if response
        response.to_s.each_line { |line| RTSP::Client.log line.strip }
      end

      response
    end

    # Sends the message over the socket.
    #
    # @return [RTSP::Response]
    def send_message
      begin
        Timeout::timeout(@timeout) do
          @socket.send(@message, 0)
          recv
        end
      rescue Timeout::Error
        raise RTSP::Exception, "Request took more than #{@timeout} seconds to send."
      end
    end

    # @return [RTSP::Response]
    def recv
      socket_data = @socket.recvfrom MAX_BYTES_TO_RECEIVE
      response = RTSP::Response.new socket_data.first

      response
    end

=begin
    def connect
      timeout(@timeout) { @socket = TCPSocket.new(@host, @port) } #rescue @socket = nil
    end

    def connected?
      @socket == nil ? true : false
    end

    def disconnect
      timeout(@timeout) { @socket.close } rescue @socket = nil
    end
=end

  end
end
