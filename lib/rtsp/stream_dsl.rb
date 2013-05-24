require 'socket'
require 'uri'
require_relative '../ext/uri_rtsp'
require 'rtp/sender'


module RTSP

  # This provides the DSL methods to Field classes and instances which make
  # defining those fields more intuitive.
  module StreamDSL
    def self.included(base)
      base.extend(DSLMethods)
    end


    module DSLMethods
      attr_reader :type
      attr_reader :source
      attr_reader :codec
      attr_accessor :mount_path
      attr_reader :rtp_sender

      def type=(new_type)
        case new_type
        when :socat
          #@transporter.type = :socat
          @type = new_type
        end
      end

      def source=(new_source)
        uri = URI(new_source)

        @source = {
          protocol: uri.scheme,
          ip: uri.host,
          port: uri.port
        }
      end

      def destination
        unless defined? Struct::Destination
          Struct.new("Destination", :ip_addressing_type, :protocol, :start_port)
          Struct::Destination.instance_exec do
            def ip_addressing_type=(type)
              puts "HI!"
            end
          end
        end

        @destination ||= Struct::Destination.new(:unicast, :UDP, 6780)
        @destination.ip_addressing_type = "pants"
      end

      def codec=(new_codec)
        @code = case new_codec
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

      # Not part of the DSL
      def description
        return @description if @description

        @description = SDP::Groups::MediaDescription.new
        @description.add_field :connection_data
        @description.seed!

        description.add_field :attribute
        description.attributes.last.type = 'control'
        description.attributes.last.value = control_url

        # Until RTP does RTCP, this needs to be here
        @description.add_field :bandwidth
        @description.bandwidths.last.modifier = 'RS'
        @description.bandwidths.last.value = 0
        @description.add_field :bandwidth
        @description.bandwidths.last.modifier = 'RR'
        @description.bandwidths.last.value = 0

        @description
      end

=begin
      def ip_addressing_type(new_type=nil)
        if new_type.nil?
          return multicast? ? :multicast : :unicast
        end

        unless [:unicast, :multicast].include? new_type
          raise "Unknown IP addressing type: #{new_type}"
        end

        if new_type == :multicast
          description.connection_data.connection_address = multicast_ip
        else
          description.connection_data.connection_address = local_ip
        end
      end

      def destination_port(new_port=nil)
        return description.media.port if new_port.nil?

        description.media.port = new_port
      end
=end

      def multicast?
        Addrinfo.ip(description.connection_data.connection_address).ipv4_multicast? ||
          Addrinfo.ip(description.connection_data.connection_address).ipv6_multicast?
      end

      #-------------------------------------------------------------------------
      # Privates
      private

      # @return [String]
      def control_url
        @mount_path[0] == ?/ ? @mount_path.sub(/\//, '') : @mount_path
      end

=begin
      def setup_rtp_sender(type)
        case type
        when :socat
          @rtp_sender = RTP::Sender.instance
          @rtp_sender.stream_module = RTP::Senders::Socat

          yield @rtp_sender if block_given?

        end
      end
=end

      def multicast_ip
        '224.2.0.1'
      end

      # Gets the local IP address.
      #
      # @return [String] The IP address.
=begin
      def local_ip
        orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

        UDPSocket.open do |s|
          s.connect '64.233.187.99', 1
          s.addr.last
        end
      ensure
        Socket.do_not_reverse_lookup = orig
      end
=end
    end
  end
end
