require_relative 'logger'
require 'sdp/description'


module RTSP
  class AbstractStream
    # This should just be a media section
    @@description = {}
    @@destination_port = 6780

    def self.type=(type)
      @@type = type
    end

    def self.source=(source)
      @@source = source
    end

    def self.destination_port=(port)
      @@destination_port = port
    end

    def self.codec=(codec)
      @@codec = codec

      case codec
      when :h264
        @@description = {
          media: :video,
          port: @@destination_port,
          format: 98,
          protocol: "RTP/AVP",
          attributes: [
            {
              attribute: 'rtpmap',
              value: '98 H264/90000'
            },
            {
              attribute: 'fmtp',
              value: "98 packetization-mode=1;profile-level-id=428032;" +
                  "sprop-parameter-sets=Z0KAMtoAgAMEwAQAAjKAAAr8gYAAAYhMAABMS0IvfjAA" +
                  "ADEJgAAJiWhF78CA,aM48gA=="
            }
          ]
        }
      end
    end

    def self.description
      @@description
    end

    attr_reader :streamer

    def initialize(path, streamer)
      @path = path
      @streamer = streamer
    end

    def play
      @streamer.play
    end

    def pause
      @streamer.pause
    end
  end
end
