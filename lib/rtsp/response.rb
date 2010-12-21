require 'rubygems'
require 'socket'

module RTSP
  class Response
    attr_reader :status
    attr_reader :body
    
    def initialize(response)
      require 'ap'
      ap response
      response_array = response.split "\r\n\r\n"
      head = response_array.first
      body = response_array.last == head ? "" : response_array.last
      parse_head(head)
      @body = parse_body(body)
    end

    def parse_head head
      lines = head.split "\r\n"

      lines.each_with_index do |line, i|
        @status = line if i == 0
        
        if line.include? ": "
          header_field = line.strip.split(": ")
          header_name = header_field.first.downcase.gsub(/-/, "_")
          create_reader(header_name, header_field.last)
        end
      end
    end

    def parse_body body
      #response[:body] = read_nonblock(size).split("\r\n") unless @content_length == 0
      @sdp_info = []
      lines = body.split "\r\n"
      
      lines.each_with_index do |line, i|
        if line =~ /^\w\=/
          @sdp_info << line
        end
      end

      lines
    end

    def create_reader(name, value)
      instance_variable_set("@#{name}", value)
      self.instance_eval "def #{name}; @#{name}; end"
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
  end
end
