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


    # The object used for sending the actual stream data.
    attr_accessor :streamer

    # The relative path on which the stream is hosted.
    attr_accessor :path

    def initialize
      @description = self.class.description
      log "Description: #{@description}"
    end

    def play
      @streamer.play
    end

    def pause
      @streamer.pause
    end
  end
end
