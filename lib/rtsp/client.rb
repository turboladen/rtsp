require 'rubygems'
require 'logger'
require 'socket'
require 'tempfile'
require 'timeout'
require 'uri'

require 'rtsp/request_messages'
require 'rtsp/response'

module RTSP

  # Allows for pulling streams from an RTSP server.
  class Client
    include RTSP::RequestMessages

    MAX_BYTES_TO_RECEIVE = 1500

    attr_reader   :server_uri
    attr_accessor :stream_tracks

    # @param [String] url URL to the resource to stream.  If no scheme is given, "rtsp"
    # is assumed.  If no port is given, 554 is assumed.  If no path is given, "/stream1"
    # is assumed.
    def initialize(url, options={})
      @server_uri = URI.parse url
      fill_out_server_uri
      @socket = options[:socket]               || TCPSocket.new(@server_uri.host, @server_uri.port)
      @stream_tracks = options[:stream_tracks] || ["/track1"]
      @timeout = options[:timeout]             || 2
      @session
      @logger = Logger.new(STDOUT)
      
      if options[:capture_file_path] && options[:capture_duration]
        @capture_file_path = options[:capture_file_path]
        @capture_duration = options[:capture_duration]
        setup_capture
      end
    end

    def setup_capture
      @capture_file = File.open(@capture_file_path, File::WRONLY|File::EXCL|File::CREAT)
      @capture_socket = UDPSocket.new
      @capture_socket.bind "0.0.0.0", @server_uri.port
    end

    # TODO: update sequence
    # @return [Hash] The response formatted as a Hash.
    def options
      @logger.debug "Sending OPTIONS to #{@server_uri.host}#{@stream_path}"
      response = send_rtsp RequestMessages.options(@server_uri.to_s)
      @logger.debug "Recieved response:"
      @logger.debug response

      @session = response.cseq

      response
    end

    # TODO: update sequence
    # TODO: get tracks, IP's, ports, multicast/unicast
    # @return [Hash] The response formatted as a Hash.
    def describe
      @logger.debug "Sending DESCRIBE to #{@server_uri.host}#{@stream_path}"
      response = send_rtsp(RequestMessages.describe(@server_uri.to_s))

      @logger.debug "Recieved response:"
      @logger.debug response.inspect

      @session = response.cseq
      @sdp_info = response.body
      @content_base = response.content_base

      response
    end

    # TODO: update sequence
    # TODO: get session
    # @return [Hash] The response formatted as a Hash.
    def setup(options={})
      #@server_uri.port = options[:port] if options[:port]
      @logger.debug "Sending SETUP to #{@server_uri.host}#{@stream_path}"
      #response = send_rtsp RequestMessages.setup("#{@server_uri.to_s}/#{@stream_tracks.first}", options)
      response = send_rtsp RequestMessages.setup(@content_base, options)

      @logger.debug "Recieved response:"
      @logger.debug response

      @session = response.cseq

      response
    end

    # TODO: update sequence
    # TODO: get session
    # @return [Hash] The response formatted as a Hash.
    def play(options={})
      @logger.debug "Sending PLAY to #{@server_uri.host}#{@stream_path}"
      session = options[:session] || @session
      response = send_rtsp RequestMessages.play(@server_uri.to_s, options[:session])

      @logger.debug "Recieved response:"
      @logger.debug response
      @session = response.cseq

      if @capture_file_path
        begin
          Timeout::timeout(@capture_duration) do
            while data = @capture_socket.recvfrom(102400).first
              @logger.debug "data size = #{data.size}"
              @capture_file_path.write data
            end
          end
        rescue Timeout::Error
          # Blind rescue
        end

        @capture_socket.close
      end

      response
    end

    def pause(options={})
      @logger.debug "Sending PAUSE to #{@server_uri.host}#{@stream_path}"
      response = send_rtsp RequestMessages.pause(@stream_tracks.first, options[:session],
        options[:sequence])

      @logger.debug "Recieved response:"
      @logger.debug response
      @session = response.cseq

      response
    end

    # @return [Hash] The response formatted as a Hash.
    def teardown
      @logger.debug "Sending TEARDOWN to #{@server_uri.host}#{@stream_path}"
      response = send_rtsp RequestMessages.teardown(@server_uri.to_s, @session)
      @logger.debug "Recieved response:"
      @logger.debug response
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
      message.each_line { |line| @logger.debug line }
      recv if timeout(@timeout) { @socket.send(message, 0) }
    end

    def aggregate_control_track
      aggregate_control = @sdp_info.attributes.find_all do |a|
        a[:attribute] == "control"
      end

      aggregate_control.first[:value]
    end

    def media_control_tracks
      tracks = []
      @sdp_info.media_sections.each do |media_section|
        media_section[:attributes].each do |a|
          tracks << a[:value] if a[:attribute] == "control"
        end
      end

      tracks
    end

    # @return [Hash]
    def recv
      size = 0
      socket_data, sender_sockaddr = @socket.recvfrom MAX_BYTES_TO_RECEIVE
      response = RTSP::Response.new socket_data

      #unless response.message == "OK"
      #  message = "Did not recieve RTSP/1.0 200 OK.  Instead got '#{response.status}'"
      #  message = message + "Full response:\n#{response.inspect}"
      #  raise message
      #
      # end
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
    #--------------------------------------------------------------------------
    # Privates!
    private

    def fill_out_server_uri
      @server_uri.scheme ||= "rtsp"
      #@server_uri.host = (@server_uri.host ? @server_uri.host : @server_uri.path)
      @server_uri.port ||= 554

      #if @server_uri.path == @server_uri.host
      #  @server_uri.path = "/stream1"
      #else
      #  @server_uri.path
      #end
puts @server_uri.host
puts @server_uri
    end
  end
end