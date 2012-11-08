require 'sdp'
require_relative 'transport_parser'


module RTSP

  # Contains common methods belonging to Request and Response classes.
  module Common

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

    # Reads through each header line of the RTSP request, extracts the
    # request code, request message, request version, and creates a
    # snake-case accessor with that value set.
    #
    # @param [String] head The section of headers from the request text.
    def parse_head_to_attrs head
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
        elsif line.include? "Transport: "
          transport_data = line.match(/\S+$/).to_s
          transport_parser = RTSP::TransportParser.new
          create_reader("transport", transport_parser.parse(transport_data))
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
    def parse_body body
      if body =~ /^(\r\n|\n)/
        body.gsub!(/^(\r\n|\n)/, '')
      end

      @body = if @content_type && @content_type.include?("application/sdp")
        SDP.parse body
      else
        body
      end
    end

    # @return [String] The unparsed request as a String.
    def to_s
      @raw_request || @raw_response || ""
    end

    # This custom redefinition of #inspect is needed because of the #to_s
    # definition.
    #
    # @return [String]
    def inspect
      me = "#<#{self.class.name}:0x#{self.object_id.to_s(16)}"

      ivars = self.instance_variables.map do |variable|
        "#{variable}=#{instance_variable_get(variable).inspect}"
      end.join(' ')

      me << " #{ivars} " unless ivars.empty?
      me << ">"

      me
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

      define_singleton_method name.to_sym do
        instance_variable_get "@#{name}".to_sym
      end
    end
  end
end
