require 'rubygems'
require 'timeout'
require 'socket'
require 'uri'
require 'logger'
require File.dirname(__FILE__) + '/request_messages'
require File.dirname(__FILE__) + '/response'

module RTSP

  # Allows for pulling streams from an RTSP server.
  class Client

    # @param [String] url URL to the resource to stream.  If no scheme is given, "rtsp"
    # is assumed.  If no port is given, 554 is assumed.  If no path is given, "/stream1"
    # is assumed.
    def initialize(url, options={})
      @uri = URI.parse url
      fill_out_uri
      @rtsp_messages = options[:rtsp_types]    || RTSP::RequestMessages.new
      @sequence = options[:sequence]           || 0
      @socket = options[:socket]               || TCPSocket.new(@uri.host, @uri.port)
      @stream_tracks = options[:stream_tracks] || ["/track1"]
      @timeout = options[:timeout]             || 2
      @session
      @logger = Logger.new(STDOUT)
    end

    def fill_out_uri
      @uri.scheme ||= "rtsp"
      @uri.host = (@uri.host ? @uri.host : @uri.path)
      @uri.port ||= 554
      #@uri.path ||= @uri.host + "/stream1"
      if @uri.path == @uri.host
        @uri.path = "/stream1"
      else
        @uri.path
      end
    end

    # TODO: update sequence
    # @return [Hash] The response formatted as a Hash.
    def options
      @logger.debug "Sending OPTIONS to #{@uri.host}#{@stream_path}"
      response = send_rtsp @rtsp_messages.options(rtsp_url(@uri.host, @stream_path))
      @logger.debug "Recieved response:"
      @logger.debug respone
    end

    # TODO: update sequence
    # TODO: get tracks, IP's, ports, multicast/unicast
    # @return [Hash] The response formatted as a Hash.
    def describe
      @logger.debug "Sending DESCRIBE to #{@uri.host}#{@stream_path}"
      response = send_rtsp(@rtsp_messages.describe(rtsp_url))

      @logger.debug "Recieved response:"
      @logger.debug response.inspect

      response
    end

    # TODO: update sequence
    # TODO: get session
    # @return [Hash] The response formatted as a Hash.
    def setup(options={})
      @uri.port = options[:port] if options[:port]
      @logger.debug "Sending SETUP to #{@uri.host}#{@stream_path}"
      response = send_rtsp @rtsp_messages.setup(rtsp_url, options)
      @session = response.session

      @logger.debug "Recieved response:"
      @logger.debug response

      response
    end

    # TODO: update sequence
    # TODO: get session
    # @return [Hash] The response formatted as a Hash.
    def play
      @logger.debug "Sending PLAY to #{@uri.host}#{@stream_path}"
      response = send_rtsp @rtsp_messages.play(rtsp_url, @session)
      @logger.debug "Recieved response:"
      @logger.debug response

      response
    end

    # @return [Hash] The response formatted as a Hash.
    def teardown
      response = send_rtsp @rtsp_messages.teardown(rtsp_url, @session)
      #@socket.close if @socket.open?
      @socket = nil

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

    # @param []
    def send_rtsp(message)
      recv if timeout(@timeout) { @socket.send(message, 0) }
    end

    # @return [Hash]
    def recv
      size = 0
      socket_data, sender_sockaddr = @socket.recvfrom 102400
      response = RTSP::Response.new socket_data
=begin
      response = parse_header
      unless response[:status].include? "RTSP/1.0 200 OK"
        message = "Did not recieve RTSP/1.0 200 OK.  Instead got '#{response[:status]}'"
        message = message + "Full response:\n#{response}"
        raise message
      end

      response[:status] = readline
      while line = readline
        break if line == "\r\n"

        if line.include? ": "
          a = line.strip().split(": ")
          response.merge!({a[0].downcase => a[1]})
        end
      end

      size = response["content-length"].to_i if response.has_key?("content-length")
      response[:body] = read_nonblock(size).split("\r\n") unless size == 0

      response
=end
      size = response.content_length.to_i if response.respond_to? 'content_length'
      #response[:body] = read_nonblock(size).split("\r\n") unless size == 0

      response
    end

    # @param [Number] size
    # @param [Hash] options
    # @option options [Number] time Duration to read on the non-blocking socket.
=begin
    def read_nonblock(size, options={})
      options[:time] ||= 1
      buffer = nil
      timeout(options[:time]) { buffer = @socket.read_nonblock(size) }

      buffer
    end

    # @return [String]
    def readline(options={})
      options[:time] ||= 1
      line = nil
      timeout(options[:time]) { line = @socket.readline }

      line
    end
=end

    # @return [String] The RTSP URL.
    def rtsp_url
      @uri.to_s
    end
  end
end