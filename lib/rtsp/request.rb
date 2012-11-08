require_relative 'error'
require_relative 'global'
require_relative 'common'

module RTSP

  # Parses raw request data from the server/client and turns it into
  # attr_readers.
  class Request
    extend RTSP::Global
    include RTSP::Common

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
          "#{self.class} received nil or empty string--this shouldn't happen."
      end

      @raw_body = raw_request
      @remote_host = remote_host

      head, body = split_head_and_body_from @raw_body
      parse_head(head)
    end
  end
end
