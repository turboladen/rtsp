require 'rubygems'
require 'sdp'
require_relative 'error'
require_relative 'global'

module RTSP

  # Parses raw request data from the server/client and turns it into
  # attr_readers.
  class Request
    extend RTSP::Global

    attr_reader :rtsp_version
    attr_reader :code
    attr_reader :message
    attr_reader :body
    attr_reader :url
    attr_reader :stream_index
    attr_accessor :remote_host

    # @param [String] raw_request The raw request string returned from the
    # server/client.
    # @param [String] remote_host The IP address of the remote host.
    def initialize(raw_request, remote_host)
      if raw_request.nil? || raw_request.empty?
        raise RTSP::Error,
          "#{self.class} received nil string--this shouldn't happen."
      end

      @raw_request = raw_request
      @remote_host = remote_host

      head, body = split_head_and_body_from @raw_request
      parse_head(head)
    end

    # @return [String] The unparsed request as a String.
    def to_s
      @raw_request
    end

    # Custom redefine to make sure all the dynamically created instance
    # variables are displayed when this method is called.
    #
    # @return [String]
    def inspect
      me = "#<#{self.class.name}:#{self.__id__} "

      self.instance_variables.each do |variable|
        me << "#{variable}=#{instance_variable_get(variable).inspect}, "
      end

      me.sub!(/, $/, "")
      me << ">"

      me
    end

    # Takes the raw request text and splits it into a 2-element Array, where 0
    # is the text containing the headers and 1 is the text containing the body.
    #
    # @param [String] raw_request
    # @return [Array<String>] 2-element Array containing the head and body of
    #   the request.  Body will be nil if there wasn't one in the request.
    def split_head_and_body_from raw_request
      head_and_body = raw_request.split("\r\n\r\n", 2)
      head = head_and_body.first
      body = head_and_body.last == head ? nil : head_and_body.last

      [head, body]
    end

    # Pulls out the RTSP version, request code, and request message (AKA the
    # status line info) into instance variables.
    #
    # @param [String] line The String containing the status line info.
    def extract_status_line(line)
      /RTSP\/(?<rtsp_version>\d\.\d)/ =~ line
      /(?<url>rtsp:\/\/.*) RTSP/ =~ line
      /rtsp:\/\/.*stream(?<stream_index>\d*)m? RTSP/ =~ line
      @url = url
      @stream_index = stream_index.to_i

      if rtsp_version.nil?
        raise RTSP::Error, "Status line corrupted: #{line}"
      end
    end

    # Returns the transport URL.
    #
    # @return [String] Transport URL associated with the request.
    def transport_url
      /client_port=(?<port>.*)-/ =~ transport

      if port.nil?
        log("Could not find client port associated with transport", :warn)
      else
        "#{@remote_host}:#{port}"
      end
    end

    # Checks if the request is for a multicast stream.
    #
    # @return [Boolean] true if the request is for a multicast stream.
    def multicast?
      return false if @url.nil?

      @url.end_with? "m"
    end

    # Reads through each header line of the RTSP request, extracts the
    # request code, request message, request version, and creates a
    # snake-case accessor with that value set.
    #
    # @param [String] head The section of headers from the request text.
    def parse_head head
      lines = head.split "\r\n"

      lines.each_with_index do |line, i|
        if i == 0
          extract_status_line(line)
          next
        end

        if line.include? "Session: "
          value = {}
          line =~ /Session: (\d+)/
          value[:session_id] = $1.to_i

          if line =~ /timeout=(.+)/
            value[:timeout] = $1.to_i
          end

          create_reader("session", value)
        elsif line.include? ": "
          header_and_value = line.strip.split(":", 2)
          header_name = header_and_value.first.downcase.gsub(/-/, "_")
          create_reader(header_name, header_and_value[1].strip)
        end
      end
    end

    private

    # Creates an attr_reader with the name given and sets it to the value
    # that's given.
    #
    # @param [String] name
    # @param [String,Hash] value
    def create_reader(name, value)
      unless value.empty?
        if value.is_a? String
          value = value =~ /^[0-9]*$/ ? value.to_i : value
        end
      end

      instance_variable_set("@#{name}", value)
      self.instance_eval "def #{name}; @#{name}; end"
    end
  end
end
