require 'rubygems'
require 'logger'
require 'socket'
require 'tempfile'
require 'timeout'
require 'uri'

require File.expand_path(File.dirname(__FILE__) + '/request')
require File.expand_path(File.dirname(__FILE__) + '/response')

module RTSP

  # Allows for pulling streams from an RTSP server.
  class Client
    attr_reader   :server_uri
    attr_accessor :stream_tracks

    # @param [String] rtsp_url URL to the resource to stream.  If no scheme is given,
    # "rtsp" is assumed.  If no port is given, 554 is assumed.  If no path is
    # given, "/stream1" is assumed.
    def initialize(rtsp_url, options={})
      #@server_uri = build_server_uri(rtsp_url)
      #@socket = options[:socket]               || TCPSocket.new(@server_uri.host,
      #                                                          @server_uri.port)
      #@stream_tracks = options[:stream_tracks] || ["/track1"]
      #@timeout = options[:timeout]             || 2
      #@session
      @logger = Logger.new(STDOUT)
      @logger.datetime_format = "%b %d %T"

=begin
      if options[:capture_file_path] && options[:capture_duration]
        @capture_file_path = options[:capture_file_path]
        @capture_duration = options[:capture_duration]
        setup_capture
      end
=end
      begin
        options = RTSP::Request.execute({ :method => :options,
            :resource_url => rtsp_url })

        @rtsp_methods = supported_methods options.public
      rescue => e
        puts e.message
        puts e.backtrace
      end
      #binding.pry
    end

    # Takes the methods returned from the Public header from an OPTIONS response
    # and puts them to an Array.
    #
    # @param [String] method_list The string returned from the server containing
    # the list of methods it supports.
    # @return [Array<Symbol>] The list of methods as symbols.
    def supported_methods method_list
      method_list.downcase.split(', ').map { |m| m.to_sym }
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
      response = send_rtsp Request.options(@server_uri.to_s)
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
      response = send_rtsp(Request.describe("#{@server_uri.to_s}#{@stream_path}"))

      @logger.debug "Recieved response:"
      @logger.debug response.inspect

      @session = response.cseq
      @sdp_info = response.body
      @content_base = response.content_base

      response
    end

    # TODO: update sequence
    # TODO: get session
    # TODO: parse Transport header (http://tools.ietf.org/html/rfc2326#section-12.39)
    # @return [Hash] The response formatted as a Hash.
    def setup(options={})
      @logger.debug "Sending SETUP to #{@server_uri.host}#{@stream_path}"
      setup_url = @content_base || "#{@server_uri.to_s}#{@stream_path}"
      response = send_rtsp Request.setup(setup_url, options)

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
      response = send_rtsp Request.play(@server_uri.to_s,
                                                options[:session])

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
      response = send_rtsp Request.pause(@stream_tracks.first,
                                                 options[:session],
                                                  options[:sequence])

      @logger.debug "Recieved response:"
      @logger.debug response
      @session = response.cseq

      response
    end

    # @return [Hash] The response formatted as a Hash.
    def teardown
      @logger.debug "Sending TEARDOWN to #{@server_uri.host}#{@stream_path}"
      response = send_rtsp Request.teardown(@server_uri.to_s, @session)
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
=end

    #--------------------------------------------------------------------------
    # Privates!
    private

    # Override Ruby's logger message format to provide our own.  Also, output
    # to STDOUT if not already outputting there.  Also, log to syslog server
    # if configured.
    #
    # @param [String] severity Describes the log level (ERROR, INFO, ...)
    # @param [DateTime] datetime The timestamp of the message to be logged
    # @param [String] progname The name of the program that is logging
    # @param [String] message The actual log message
    # @return [String] The formatted message with ANSI codes stripped.
    def format_message(severity, datetime, progname, message)
      prog_name = " <#{progname}>" if progname

      # Use the constant's setting unless we decide to redefine datetime_format.
      datetime_format = DATETIME_FORMAT unless datetime_format
      datetime = datetime.strftime(datetime_format).to_s

      outstr = "[#{datetime}]:#{COLOR_MAP[severity]}:#{prog_name} #{message}\n"
      puts outstr unless @log_file_location == STDOUT

      if @log_server_status
        server_log(severity, datetime, progname, message)
      end

      # Delete all ANSI codes in returned String.
      if @log_file_location == STDOUT
        outstr
      else
        outstr.gsub(/\x1B\[[0-9;]*[mK]/, '')
      end
    end
  end
end