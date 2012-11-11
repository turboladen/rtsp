require_relative 'client'
require 'rtp/sender'
require 'sdp'
require 'etc'
require 'socket'


module RTSP
  class Stream
    # To convert Unix time to NTP time, add this.
    NTP_TO_UNIX_TIME_DIFF = 2208988800

    attr_accessor :description
    attr_accessor :uri
    attr_accessor :remote_uri
    attr_accessor :rtp_sender

    def initialize
      yield self if block_given?

      @uri ||= "/stream1"

      if @remote_uri
        client = RTSP::Client.new(@remote_uri)
        remote_description = client.describe
        @description = remote_description.body
      else
        @rtp_sender ||= RTP::Sender.instance
        @description ||= default_description
      end
    end

    def default_description
      sdp = SDP::Description.new
      sdp.username = Etc.getlogin
      sdp.id = Time.now.to_i + NTP_TO_UNIX_TIME_DIFF
      sdp.version = sdp.id
      sdp.network_type = "IN"
      sdp.address_type = "IP4"

      sdp.unicast_address = UDPSocket.open do |s|
        s.connect('64.233.187.99', 1); s.addr.last
      end

      sdp.name = "Ruby RTSP Stream"
      sdp.information = "This is a Ruby RTSP stream"
      sdp.connection_network_type = "IN"
      sdp.connection_address_type = "IP4"
      sdp.connection_address = sdp.unicast_address
      sdp.start_time = 0
      sdp.stop_time = 0

      # User must still define media section.
    end

  end
end
