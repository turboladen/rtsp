require 'sdp'
require_relative 'error'
require_relative 'common'

module RTSP

  # Parses raw response data from the server/client and turns it into
  # attr_readers.
  class Response
    include RTSP::Common
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

      @raw_body = raw_response

      head, body = split_head_and_body_from @raw_body
      parse_head(head)
      @body = parse_body(body)
    end

    # Pulls out the RTSP version, response code, and response message (AKA the
    # status line info) into instance variables.
    #
    # @param [String] line The String containing the status line info.
    def extract_status_line(line)
      line =~ /RTSP\/(\d\.\d) (\d\d\d) ([^\r\n]+)/
      @rtsp_version = $1
      @code         = $2.to_i
      @message      = $3

      if @rtsp_version.nil?
        raise RTSP::Error, "Status line corrupted: #{line}"
      end
    end
  end
end
