require 'rubygems'
require 'socket'
require 'sdp'

module RTSP
  class Response
    attr_reader :code
    attr_reader :message
    attr_reader :body
    
    def initialize(response)
      response_array = response.split "\r\n\r\n"
      if response_array.empty?
        response_array = response.split "\n\n"
      end

      head = response_array.first
      body = response_array.last == head ? "" : response_array.last
      parse_head(head)
      @body = parse_body(body)
    end

    # Reads through each line of the RTSP response and creates a
    # snake-case accessor with that value set.
    #
    # @param [String] head
    def parse_head head
      lines = head.split "\r\n"

      lines.each_with_index do |line, i|
        if i == 0
          line =~ /RTSP\/1.0 (\d\d\d) ([^\r\n]+)/
          @code = $1.to_i
          @message = $2
          next
        end
        
        if line.include? ": "
          header_field = line.strip.split(": ")
          header_name = header_field.first.downcase.gsub(/-/, "_")
          create_reader(header_name, header_field.last)
        end
      end
    end

    def parse_body body
      #response[:body] = read_nonblock(size).split("\r\n") unless @content_length == 0
      if body =~ /^(\r\n|\n)/
        body.gsub!(/^(\r\n|\n)/, '')
      end

      if @content_type == "application/sdp"
        return SDP.parse body
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

=begin
    def inspect
      message = "<#{self.class} "
      instance_variables.each do |v|
        message << v.to_s + "=" + instance_variable_get("#{v}")
      end
      message << " }>"
    end
=end
    private

    def create_reader(name, value)
      instance_variable_set("@#{name}", value)
      self.instance_eval "def #{name}; @#{name}; end"
    end
  end
end
