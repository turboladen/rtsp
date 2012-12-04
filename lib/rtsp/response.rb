require_relative 'message'
require 'time'
require 'rack/response'
require 'rack/utils'


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

        unless body && body.empty?
          new_response.instance_variable_set(:@raw, raw_response)
          new_response.parse_body(body)
        end

        new_response
      end
    end

    RTSP_SPECIFIC_STATUS_CODES = {
      250 => 'Low on Storage Space',
      405 => 'Method Not Allowed',
      451 => 'Parameter Not Understood',
      452 => 'Conference Not Found',
      453 => 'Not Enough Bandwidth',
      454 => 'Session Not Found',
      455 => 'Method Not Valid in This State',
      456 => 'Header Field Not Valid for Resource',
      457 => 'Invalid Range',
      458 => 'Parameter Is Read-Only',
      459 => 'Aggregate Operation Not Allowed',
      460 => 'Only Aggregate Operation Allowed',
      461 => 'Unsupported Transport',
      462 => 'Destination Unreachable',
      551 => 'Option not supported'
    }

    HTTP_STATUS_CODES = Rack::Utils::HTTP_STATUS_CODES
    RTSP_STATUS_CODES = HTTP_STATUS_CODES.merge(RTSP_SPECIFIC_STATUS_CODES)

    attr_reader :code
    attr_reader :status_message

    def initialize(status=nil, body="")
      super()
      @code = status
      @status_message = RTSP_STATUS_CODES[status] if status
      @body = body

      yield self if block_given?
    end

    # Pulls out the RTSP version, response code, and response message (AKA the
    # status line info) into instance variables.
    #
    # @param [String] line The String containing the status line info.
    def extract_status_line(line)
      /(RTSP|HTTP)\/(?<rtsp_version>\d.\d) (?<code>\d\d\d) (?<status_message>[^\r\n]+)/ =~
        line

      @rtsp_version = rtsp_version
      @code = code.to_i
      @status_message = status_message

      if @rtsp_version.nil?
        raise RTSP::Error, "Status line corrupted: #{line}"
      end
    end

    def status_line
      "RTSP/#{@rtsp_version} #{@code} #{@status_message}\r\n"
    end

    def default_headers
      headers = {}

      headers['CSeq'] ||= RTSP_DEFAULT_SEQUENCE_NUMBER
      headers['Date'] = Time.now.httpdate

      headers
    end

    def rack_response
      [@code, @headers, @body]
    end
  end
end
