require 'rubygems'
require 'logger'
require 'socket'
require 'tempfile'
require 'timeout'
require 'uri'

require File.expand_path(File.dirname(__FILE__) + '/request')
require File.expand_path(File.dirname(__FILE__) + '/response')
require File.expand_path(File.dirname(__FILE__) + '/helpers')

module RTSP

  # Allows for pulling streams from an RTSP server.
  class Client
    include RTSP::Helpers

    attr_reader :options
    attr_reader :server_uri
    attr_reader :cseq
    attr_accessor :tracks

    # @param [String] rtsp_url URL to the resource to stream.  If no scheme is given,
    # "rtsp" is assumed.  If no port is given, 554 is assumed.  If no path is
    # given, "/stream1" is assumed.
    def initialize(rtsp_url, args={})
      @server_uri = build_resource_uri_from rtsp_url
      @args = args

      @cseq = 1
      #@tracks = options[:tracks] || ["/track1"]
      @logger = Logger.new(STDOUT)
      @logger.datetime_format = "%b %d %T"

=begin
      if options[:capture_file_path] && options[:capture_duration]
        @capture_file_path = options[:capture_file_path]
        @capture_duration = options[:capture_duration]
        setup_capture
      end
=end
      #binding.pry
    end

    # The URL for the RTSP server to talk to can change if multiple servers are
    # involved in delivering content.  This method can be used to change the
    # server to talk to on the fly.
    #
    # @param [String] new_url The new server URL to use to communicate over.
    def server_url=(new_url)
      @server_uri = build_resource_uri_from new_url
    end

    # Sends an OPTIONS message to the server specified by @server_uri.  Sets
    # @supported_methods based on the list of supported methods returned in the
    # Public headers.  Lastly, if the response was an OK, it increases the @cseq
    # value so that the next uses that.
    #
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    def options additional_headers={}
      headers = ( { :cseq => @cseq }).merge(additional_headers)
      @logger.debug "Sending OPTIONS to #{@server_uri.to_s}"

      begin
        response = RTSP::Request.execute(@args.merge(
            :method => :options,
            :resource_url => @server_uri,
            :headers => headers
        ))

        @logger.debug "Received response:"
        @logger.debug response.inspect

        @supported_methods = extract_supported_methods_from response.public
        compare_sequence_number response.cseq
        @cseq += 1
      rescue => ex
        puts "Got #{ex.message}"
        puts ex.backtrace
      end

      response
    end

    # TODO: get tracks, IP's, ports, multicast/unicast
    # @param [Hash] additional_headers
    # @return [RTSP::Response]
    def describe additional_headers={}
      headers = ( { :cseq => @cseq }).merge(additional_headers)
      @logger.debug "Sending DESCRIBE to #{@server_uri.host}#{@stream_path}"

      begin
        response = RTSP::Request.execute(@args.merge(
            :method => :describe,
            :resource_url => @server_uri,
            :headers => headers
        ))

        @logger.debug "Received response:"
        @logger.debug response.inspect

        compare_sequence_number response.cseq
        @cseq += 1
        @session_description = response.body
        @content_base = response.content_base
        @session_id = response.id

        @media_control_tracks = media_control_tracks
        @aggregate_control_track = aggregate_control_track
      rescue => ex
        puts "Got #{ex.message}"
        puts ex.backtrace
      end

      response
    end

    # Compares the sequence number passed in to the current client sequence
    # number (@cseq) and raises if they're not equal.  If that's the case, the
    # server responded to a different request.
    #
    # @param [Fixnum] server_cseq Sequence number returned by the server.
    # @raise
    def compare_sequence_number server_cseq
      if @cseq != server_cseq
        message = "Sequence number mismatch.  Client: #{@cseq}, Server: #{server_cseq}"
        raise message
      end
    end

    # Takes the methods returned from the Public header from an OPTIONS response
    # and puts them to an Array.
    #
    # @param [String] method_list The string returned from the server containing
    # the list of methods it supports.
    # @return [Array<Symbol>] The list of methods as symbols.
    def extract_supported_methods_from method_list
      method_list.downcase.split(', ').map { |m| m.to_sym }
    end

    def setup_capture
      @capture_file = File.open(@capture_file_path, File::WRONLY|File::EXCL|File::CREAT)
      @capture_socket = UDPSocket.new
      @capture_socket.bind "0.0.0.0", @server_uri.port
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
      response = send_rtsp Request.pause(@tracks.first,
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

    def aggregate_control_track
      aggregate_control = @session_description.attributes.find_all do |a|
        a[:attribute] == "control"
      end

      "#{@content_base}#{aggregate_control.first[:value]}"
    end

    # Extracts the value of the "control" attribute from all media sections of
    # the session description (SDP).  You have to call the #describe method in
    # order to get the session description info.
    #
    # @return [Array] The tracks made up of the content base + control track
    # value.
    def media_control_tracks
      tracks = []
      @session_description.media_sections.each do |media_section|
        media_section[:attributes].each do |a|
          tracks << "#{@content_base}#{a[:value]}" if a[:attribute] == "control"
        end
      end

      tracks
    end

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