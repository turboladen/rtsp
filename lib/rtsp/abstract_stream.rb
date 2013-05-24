require 'sdp/description'
require 'rtp/session'

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

    attr_reader :rtp_session

    def initialize
      @description = self.class.description

      destination = {
        protocol: self.class.destination.protocol,
        port: self.class.destination.start_port
      }

      @rtp_session = RTP::Session.new(destination, self.class.source)
    end

    def transport_protocol
      self.class.transport_protocol
    end

    def transport_address_type
      multicast? ? :multicast : :unicast
    end

    def multicast?
      self.class.multicast?
    end

    def control_url
      self.class.control_url
    end

    def play(start_time, stop_time)
      rtp_sender.play(start_time, stop_time)
    end

    def pause
      rtp_sender.pause
    end

    # The object used for sending the actual stream data.
    def rtp_sender
      self.class.rtp_sender
    end

    def lower_transport
      self.class.destination_protocol
    end

    # @todo Figure out lower transport for TCP
    # @todo interleave streams
    # @todo setup listener for sever_port
    def transport_data(env)
      RTSP::Logger.log "Session transport info..."

      destination_address = env['rtsp.remote_address']
      requested = env['RTSP_TRANSPORT']

      transport = "#{transport_protocol}"
      transport << "/#{rtp_sender.socket_type}" if rtp_sender.socket_type == :TCP
      transport << ";#{transport_address_type}"
      transport << ";destination=#{destination_address}"

      if transport_address_type == :multicast
        rtp_port = (requested[:port][:rtp] || rtp_sender.rtp_port).to_i
        rtcp_port = (requested[:port][:rtcp] || rtp_sender.rtcp_port).to_i

        transport << ";ttl=4"
        transport << ";port=#{rtp_port}-#{rtcp_port}"
      else
        rtp_port = (requested[:client_port][:rtp] || rtp_sender.rtp_port).to_i
        rtcp_port = (requested[:client_port][:rtcp] ||rtp_sender.rtcp_port).to_i

        transport << ";client_port=#{rtp_port}-#{rtcp_port}"
        transport << ";server_port=#{rtp_port + 100}-#{rtcp_port + 100}"
        transport << ";ssrc=#{rtp_sender.ssrc}"
      end

      transport
    end
  end
end
