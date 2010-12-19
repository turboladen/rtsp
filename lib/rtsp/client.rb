require 'rubygems'
require 'timeout'
require 'socket'
require File.dirname(__FILE__) + '/request_messages'

module RTSP

  # Allows for pulling streams from an RTSP server.
  class Client
    def initialize(url, options={})
      uri = URI.parse url
      @scheme = uri.scheme || "rtsp"
      @host = (uri.host ? uri.host : uri.path)
      @port = uri.port || 554
      @path = uri.host ? uri.path : "/stream1"
      @rtsp_messages = options[:rtsp_types]   || RTSP::RequestMessages.new
      @sequence = options[:sequence]          || 0
      @socket = options[:socket]              || TCPSocket.new(@host, @port)
      @stream_tracks = options[:stream_tacks] || ["/track1"]
      @timeout = options[:timeout]            || 2
      @session
    end

    # TODO: update sequence
    # @return [Hash] The response formatted as a Hash.
    def options
      send @rtsp_messages.options(rtsp_url(@host, @stream_path))
    end

    # TODO: update sequence
    # TODO: get tracks, IP's, ports, multicast/unicast
    # @return [Hash] The response formatted as a Hash.
    def describe
      send @rtsp_messages.describe(rtsp_url(@host, @stream_path))
    end

    # TODO: update sequence
    # TODO: get session
    # @return [Hash] The response formatted as a Hash.
    def setup(options={})
      response = send @rtsp_messages.setup(rtsp_url(@host, @stream_path+@stream_tracks[0]), options)
      @session = response["session"]

      response
    end

    # TODO: update sequence
    # TODO: get session
    # @return [Hash] The response formatted as a Hash.
    def play
      send @rtsp_messages.play(rtsp_url(@host, @stream_path), @session)
    end

    # @return [Hash] The response formatted as a Hash.
    def teardown
      response = send @rtsp_messages.teardown(rtsp_url(@host, @stream_path), @session)
      #@socket.close if @socket.open?
      @socket = nil

      response
    end

    def connect
      timeout(@timeout) { @socket = TCPSocket.new(@host, @port) } #rescue @socket = nil
    end

    def connected?
      @socket == nil ? true : false
    end

    def disconnect
      timeout(@timeout) { @socket.close } rescue @socket = nil
    end

    # @param [?]
    def send(message)
      recv if timeout(@timeout) { @socket.send(message, 0) }
    end

    # @return [Hash]
    def recv
      response = Hash.new
      size = 0

      response[:status] = readline
      unless response[:status].include? "RTSP/1.0 200 OK"
        message = "Did not recieve RTSP/1.0 200 OK.  Instead got '#{response[:status]}'"
        message = message + "Full response:\n#{response}"
        raise message
      end

      while line = readline
        break if line == "\r\n"

        if line.include? ": "
          a = line.strip().split(": ")
          response.merge!({a[0].downcase => a[1]})
        end
      end

      size = response["Content-Length"].to_i if response.has_key?("Content-Length")
      response[:body] = read_nonblock(size).split("\r\n") unless size == 0

      response
    end

    # @param [Number] size
    # @param [Hash] options
    # @option options [Number] time Duration to read on the non-blocking socket.
    def read_nonblock(size, options={})
      options[:time] ||= 1
      buffer = nil
      timeout(options[:time]) { buffer = @socket.read_nonblock(size) }

      buffer
    end

    # @return [String]
    def readline(options = {})
      options[:time] ||= 1
      line = nil
      timeout(options[:time]) { line = @socket.readline }

      line
    end

    # @param [String] host
    # @param [String] path
    # @return [String] The RTSP URL.
    # TODO: Maybe this should return a URI instead?
    # TODO: Looks like this could also be rtspu:// (RFC Section 3.2)
    # TODO: Looks like this should also take a port (RFC Section 3.2)
    def rtsp_url(host, path)
      "rtsp://#{host}#{path}"
    end
  end
end