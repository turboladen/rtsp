require_relative '../ext/uri_rtsp'


module RTSP

  # This provides the DSL methods to Field classes and instances which make
  # defining those fields more intuitive.
  module StreamDSL
    def self.included(base)
      base.extend(DSLMethods)
    end


    module DSLMethods
      attr_accessor :type
      attr_accessor :source_url
      attr_accessor :destination_path
      attr_reader :codec

      def codec=(new_codec)
        case new_codec
        when :h264
          description.media.type = :video
          description.media.port ||= 6780
          description.media.protocol ||= "RTP/AVP"
          description.media.format ||= 98

          description.add_field :attribute
          description.attributes.last.type = 'control'
          description.attributes.last.value = control_url

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
        return @description if @description

        @description = SDP::Groups::MediaDescription.new
        @description.add_field :connection_data
        @description.seed!

        @description
      end

      def destination_ip=(ip)
        description.connection_data.connection_address = ip
        description.attributes.first.value = control_url
      end

      def destination_ip
        description.connection_data.connection_address
      end

      def destination_port=(new_port)
        description.media.port = new_port
        description.attributes.first.value = control_url
      end

      def destination_port
        description.media.port
      end

      def destination_protocol=(new_protocol)
        @destination_protocol = new_protocol
        description.attributes.first.value = control_url
      end

      def destination_port
        description.media.port
      end

      def multicast?
        m = description.connection_data.connection_address.match(/^(?<octet>\d\d?\d\?)/)

        m[:octet].to_i >= 224 && m[:octet].to_i <= 239
      end

      # @return [String]
      def control_url
        scheme = if @destination_protocol.nil? || @destination_protocol == :tcp
          "rtsp"
        elsif @destination_protocol == :udp
          "rtspu"
        else
          raise "Invalid destination protocol for control URL: #{@destination_protocol}"
        end

        url = URI("#{scheme}://#{destination_ip}:#{destination_port}")
        url.path = @destination_path

        url.to_s
      end
    end
  end
end
