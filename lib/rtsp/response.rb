require 'rubygems'
require 'sdp'
require_relative 'error'

module RTSP

  # Parses raw response data from the server/client and turns it into
  # attr_readers.
  class Response
    attr_reader :rtsp_version
    attr_reader :code
    attr_reader :message
    attr_reader :body

    # @param [String] raw_response The raw response string returned from the
    # server/client.
    def initialize(raw_response)
      if raw_response.nil? || raw_response.empty?
        raise RTSP::Error,
          "#{self.class} received nil string--this shouldn't happen."
      end

      @raw_response = raw_response

      head, body = split_head_and_body_from @raw_response
      parse_head(head)
      @body = parse_body(body)
    end

    # @return [String] The unparsed response as a String.
    def to_s
      @raw_response
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

    # Takes the raw response text and splits it into a 2-element Array, where 0
    # is the text containing the headers and 1 is the text containing the body.
    #
    # @param [String] raw_response
    # @return [Array<String>] 2-element Array containing the head and body of
    #   the response.  Body will be nil if there wasn't one in the response.
    def split_head_and_body_from raw_response
      head_and_body = raw_response.split("\r\n\r\n", 2)
      head = head_and_body.first
      body = head_and_body.last == head ? nil : head_and_body.last

      [head, body]
    end

    # Pulls out the RTSP version, response code, and response message (AKA the
    # status line info) into instance variables.
    #
    # @param [String] line The String containing the status line info.
    def extract_status_line(line)
      line =~ /RTSP|HTTP\/(\d\.\d) (\d\d\d) ([^\r\n]+)/
      @rtsp_version = $1
      @code         = $2.to_i
      @message      = $3

      if @rtsp_version.nil?
        raise RTSP::Error, "Status line corrupted: #{line}"
      end
    end

    # Reads through each header line of the RTSP response, extracts the
    # response code, response message, response version, and creates a
    # snake-case accessor with that value set.
    #
    # @param [String] head The section of headers from the response text.
    def parse_head head
      lines = head.split "\r\n"

      lines.each_with_index do |line, i|
        if i == 0
          extract_status_line(line)
          next
        end

        if line.include? "Session: "
          value = {}
          line =~ /Session: ([\w\\$\-\.\+]+)/
          value[:session_id] = $1

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

    # Reads through each line of the RTSP response body and parses it if
    # needed.  Returns a SDP::Description if the Content-Type is
    # 'application/sdp', otherwise returns the String that was passed in.
    #
    # @param [String] body
    # @return [SDP::Description,String]
    def parse_body body
      if body =~ /^(\r\n|\n)/
        body.gsub!(/^(\r\n|\n)/, '')
      end

      if @content_type == "application/sdp"
        SDP.parse body
      else
        body
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
