require_relative 'error'
require_relative 'global'
require_relative 'common'

module RTSP

  # Parses raw request data from the server/client and turns it into
  # attr_readers.
  class Request
    extend RTSP::Global
    include RTSP::Common

    # @param [String] raw_request The raw request data received on the socket.
    # @param [Socket::UDPSource] udp_source
    def self.parse(raw_request)
      if raw_request.nil? || raw_request.empty?
        raise RTSP::Error,
          "#{self.class} received nil or empty string--this shouldn't happen."
      end

      /^(?<action>\w+)/ =~ raw_request

      new do |new_request|
        head, body = new_request.split_head_and_body_from(raw_request)
        new_request.action = action.downcase.to_sym
        new_request.parse_head_to_attrs(head)

        unless body.empty?
          new_request.raw_body = body
          new_request.parse_body(body)
        end
      end
    end

    attr_accessor :action
    attr_accessor :body
    attr_accessor :raw_body

    def initialize
      @rtsp_version = '1.0'

      yield self if block_given?
    end
  end
end
