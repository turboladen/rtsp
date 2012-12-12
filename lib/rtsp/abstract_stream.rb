require 'sdp/description'

require_relative 'stream_dsl'
require_relative 'logger'


module RTSP
  # This class is used by RTSP::Application for templating streams that users
  # define for the app to serve up.  The Application further defines a stream
  # class (that inherits from this) at run time, given the info from the user
  # while defining the application.
  #
  # This class should probably never be instantiated manually.
  class AbstractStream
    include RTSP::StreamDSL
    include LogSwitch::Mixin

    # The SDP description for the stream.  This should only be the media section
    # of a description, and should thus use a SDP::Groups::MediaDescription.
    attr_reader :description

    # The relative path on which the stream is hosted.
    attr_accessor :path

    def initialize
      @description = self.class.description
    end

    def transport_protocol
      self.class.transport_protocol
    end

    def multicast?
      self.class.multicast?
    end

    def play
      rtp_sender.play
    end

    def pause
      rtp_sender.pause
    end

    # The object used for sending the actual stream data.
    def rtp_sender
      self.class.rtp_sender
    end
  end
end
