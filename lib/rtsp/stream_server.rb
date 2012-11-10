require 'rtp/sender'
require 'sdp'


module RTSP
  class Stream

    attr_reader :description

    def initialize
      @uri = "/stream1"
      @description = SDP::Description.new
      @rtp_sender = RTP::Sender.instance
    end

  end
end
