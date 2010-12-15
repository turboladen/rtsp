require 'rubygems'
require 'pathname'
require 'timeout'
require 'socket'
require File.dirname(__FILE__) + '/rtsp_client/request_messages'

#  Document me!
class RTSPClient
  VERSION = '0.0.1'
  WWW = 'http://github.com/turboladen/rtsp_client'
  LIBRARY_ROOT = File.dirname(__FILE__)
  PROJECT_ROOT = Pathname.new(LIBRARY_ROOT).parent

  def initialize(options={})
    @rtsp_messages = options[:rtsp_types]   || RTSPClient::RequestMessages.new
    @host = options[:host]                  || "127.0.0.1"
    @port = options[:port]                  || 554
    @sequence = options[:sequence]          || 0
    @socket = options[:socket]              || TCPSocket.new(@host, @port)
    @stream_path = options[:stream_path]    || "/stream1"
    @stream_tracks = options[:stream_tacks] || ["/track1"]
    @session
  end

  def options
    response = send @rtsp_messages.options(rtsp_url(@host, @stream_path))
    #TODO: update sequence
  end

  def describe
    response = send @rtsp_messages.describe(rtsp_url(@host, @stream_path))
    #TODO: update sequence
    #TODO: get tracks, IP's, ports, multicast/unicast
  end

  def setup(options={})
    response = send @rtsp_messages.setup(rtsp_url(@host, @stream_path+@stream_tracks[0]), options)
    @session = response["session"]
    #TODO: update sequence
    #TODO: get session
  end

  def play
    response = send @rtsp_messages.play(rtsp_url(@host, @stream_path), @session)
    #TODO: update sequence
    #TODO: get session
  end

  def teardown
    response = send @rtsp_messages.teardown(rtsp_url(@host, @stream_path), @session)
    #@socket.close if @socket.open?
    @socket = nil
  end

  def connect
    timeout(2) { @socket = TCPSocket.new(@host, @port) } #rescue @socket = nil
  end

  def connected?
    true unless @socket == nil
  end

  def disconnect
    timeout(2) { @socket.close } rescue @socket = nil
  end

  def send(message)
    recv if timeout(2) { @socket.send(message, 0) }
  end

  def recv
    response = Hash.new
    size = 0

    response[:status] = readline
    unless response[:status].include? "RTSP/1.0 200 OK"
      message = "Did not recieve RTSP/1.0 200 OK.  Instead got '#{response[:status]}'"
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
    return response
  end

  def read_nonblock(size, options = {})
    options[:time] ||= 1
    buffer = nil
    timeout(options[:time]) { buffer = @socket.read_nonblock(size) }
    return buffer
  end

  def readline(options = {})
    options[:time] ||= 1
    line = nil
    timeout(options[:time]) { line = @socket.readline }
    return line
  end

  def rtsp_url(host, path)
    "rtsp://#{host}#{path}"
  end
end
