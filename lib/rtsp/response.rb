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

    HTTP_STATUS_CODES = {
      100 => 'Continue',
      101 => 'Switching Protocols',
      102 => 'Processing',
      200 => 'OK',
      201 => 'Created',
      202 => 'Accepted',
      203 => 'Non-Authoritative Information',
      204 => 'No Content',
      205 => 'Reset Content',
      206 => 'Partial Content',
      207 => 'Multi-Status',
      208 => 'Already Reported',
      226 => 'IM Used',
      300 => 'Multiple Choices',
      301 => 'Moved Permanently',
      302 => 'Found',
      303 => 'See Other',
      304 => 'Not Modified',
      305 => 'Use Proxy',
      306 => 'Reserved',
      307 => 'Temporary Redirect',
      308 => 'Permanent Redirect',
      400 => 'Bad Request',
      401 => 'Unauthorized',
      402 => 'Payment Required',
      403 => 'Forbidden',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      406 => 'Not Acceptable',
      407 => 'Proxy Authentication Required',
      408 => 'Request Timeout',
      409 => 'Conflict',
      410 => 'Gone',
      411 => 'Length Required',
      412 => 'Precondition Failed',
      413 => 'Request Entity Too Large',
      414 => 'Request-URI Too Long',
      415 => 'Unsupported Media Type',
      416 => 'Requested Range Not Satisfiable',
      417 => 'Expectation Failed',
      422 => 'Unprocessable Entity',
      423 => 'Locked',
      424 => 'Failed Dependency',
      425 => 'Reserved for WebDAV advanced collections expired proposal',
      426 => 'Upgrade Required',
      427 => 'Unassigned',
      428 => 'Precondition Required',
      429 => 'Too Many Requests',
      430 => 'Unassigned',
      431 => 'Request Header Fields Too Large',
      500 => 'Internal Server Error',
      501 => 'Not Implemented',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      504 => 'Gateway Timeout',
      505 => 'HTTP Version Not Supported',
      506 => 'Variant Also Negotiates (Experimental)',
      507 => 'Insufficient Storage',
      508 => 'Loop Detected',
      509 => 'Unassigned',
      510 => 'Not Extended',
      511 => 'Network Authentication Required'
    }

    RTSP_STATUS_CODES = HTTP_STATUS_CODES.merge(RTSP_SPECIFIC_STATUS_CODES)

    attr_reader :code
    attr_reader :status_message

    def initialize(status=nil, body="")
      @code = status
      @status_message = RTSP_STATUS_CODES[status] if status
      @body = body
      super()

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

    def default_headers
      headers = {}

      headers[:cseq] ||= RTSP_DEFAULT_SEQUENCE_NUMBER

      headers
    end
  end
end
