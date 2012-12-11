module RTSP

  # This provides the DSL methods to Field classes and instances which make
  # defining those fields more intuitive.
  module StreamDSL
    def self.included(base)
      base.extend(DSLMethods)
    end


    module DSLMethods
      attr_accessor :type
      attr_accessor :source
      attr_reader :codec
      attr_reader :description

      def codec=(new_codec)
        case new_codec
        when :h264
          description.media.type = :video
          description.media.port ||= 6780
          description.media.protocol ||= "RTP/AVP"
          description.media.format ||= 98

          description.add_field :attribute
          description.attributes.last.type = 'rtpmap'
          description.attributes.last.value = '98 H264/90000'

          description.add_field :attribute
          description.attributes.last.type = 'fmtp'
          description.attributes.last.value = "98 packetization-mode=1;" +
            "profile-level-id=428032;" +
            "sprop-parameter-sets=Z0KAMtoAgAMEwAQAAjKAAAr8gYAAAYhMAABMS0IvfjAA" +
            "ADEJgAAJiWhF78CA,aM48gA=="
        end
      end

      def description
        @description ||= SDP::Groups::MediaDescription.new.seed!
      end

      def destination_port=(new_port)
        @description.port = new_port
      end

      def destination_port
        @description.port
      end
    end
  end
end
