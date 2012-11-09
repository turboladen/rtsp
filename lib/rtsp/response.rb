require_relative 'message'


module RTSP

  # Parses raw response data from the server/client and turns it into
  # attr_readers.
  class Response < Message

    # @param [String] raw_response The raw response string returned from the
    #   server/client.
    def self.parse(raw_response)
      if raw_response.nil? || raw_response.empty?
        raise RTSP::Error,
          "#{self.class} received nil string--this shouldn't happen."
      end

      new do |new_response|
        head, body = new_response.split_head_and_body_from(raw_response)
        new_response.parse_head(head)

        if body && !body.empty?
          new_response.instance_variable_set(:@raw, raw_response)
          new_response.parse_body(body)
        end

        new_response
      end
    end

    attr_reader :code
    attr_reader :status_message

    def initialize
      yield self if block_given?
    end

    # Pulls out the RTSP version, response code, and response message (AKA the
    # status line info) into instance variables.
    #
    # @param [String] line The String containing the status line info.
    def extract_status_line(line)
      line =~ /RTSP\/(\d\.\d) (\d\d\d) ([^\r\n]+)/
      @rtsp_version = $1
      @code         = $2.to_i
      @status_message      = $3

      if @rtsp_version.nil?
        raise RTSP::Error, "Status line corrupted: #{line}"
      end
    end

    def status_line
      "RTSP/#{@rtsp_version} #{@code} #{@status_message}\r\n"
    end
  end
end
