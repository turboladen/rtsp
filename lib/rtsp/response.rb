require 'socket'

require 'rubygems'
require 'sdp'

module RTSP

  # Parses raw response data from the server/client and turns it into
  # attr_readers.
  class Response
    attr_reader :rtsp_version
    attr_reader :code
    attr_reader :message
    attr_reader :body
    attr_reader :raw_response

    # @param [String] raw_response The raw response string returned from the
    # server/client.
    def initialize(raw_response)
      @raw_response = raw_response

      head_and_body = split_head_and_body_from raw_response
      head = head_and_body.first
      body = head_and_body.last == head ? "" : head_and_body.last
      parse_head(head)
      @body = parse_body(body)
    end

    def to_s
      @raw_response
    end

    # Takes the raw response text and splits it into a 2-element Array, where 0
    # is the text containing the headers and 1 is the text containing the body.
    #
    # @param [String] raw_response
    # @return [Array<String>] 2-element Array containing the head and body of
    # the response.
    def split_head_and_body_from raw_response
      response_array = raw_response.split "\r\n\r\n"

      if response_array.empty?
        response_array = raw_response.split "\n\n"
      end

      response_array
    end

    # Reads through each header line of the RTSP response, extracts the response
    # code, response message, response version, and creates a snake-case
    # accessor with that value set.
    #
    # @param [String] head
    def parse_head head
      lines = head.split "\r\n"

      lines.each_with_index do |line, i|
        if i == 0
          line =~ /RTSP\/(\d\.\d) (\d\d\d) ([^\r\n]+)/
          @rtsp_version = $1
          @code = $2.to_i
          @message = $3
          next
        end
        
        if line.include? ": "
          header_and_value = line.strip.split(":", 2)
          header_name = header_and_value.first.downcase.gsub(/-/, "_")
          create_reader(header_name, header_and_value[1].strip)
        end
      end
    end

    # Reads through each line of the RTSP response body and parses it if
    # needed.
    #
    # @param [String] body
    def parse_body body
      #response[:body] = read_nonblock(size).split("\r\n") unless @content_length == 0
      if body =~ /^(\r\n|\n)/
        body.gsub!(/^(\r\n|\n)/, '')
      end

      if @content_type == "application/sdp"
        SDP.parse body
      end
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

    private

    # Creates an attr_reader with the name given and sets it to the value that's
    # given.
    #
    # @param [String] name
    # @param [String] value
    def create_reader(name, value)
      unless value.empty?
        value = value =~ /^[0-9]*$/ ? value.to_i : value
      end

      instance_variable_set("@#{name}", value)
      self.instance_eval "def #{name}; @#{name}; end"
    end
  end
end
