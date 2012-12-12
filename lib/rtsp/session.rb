require_relative '../ext/time_ext'
require_relative 'logger'


module RTSP
  # Because RTSP does not use a persistent connection to communicate over, it
  # must maintain state of its streams and the clients using them via different
  # means; it uses sessions for this.  This differs from HTTP, which is a
  # stateless protocol.
  #
  # The RFC describes this as:
  #   A complete RTSP "transaction", e.g., the viewing of a movie.  A session
  #   typically consists of a client setting up a transport mechanism for the
  #   continuous media stream (SETUP), starting the stream with PLAY or RECORD,
  #   and closing the stream with TEARDOWN.
  #
  # Objects of this type are used by RTSP::Applications and RTSP::Clients to keep
  # track of their session state and manage the resources associated to them.
  class Session
    include LogSwitch::Mixin

    # The identifier that labels this session.
    attr_reader :id

    # @return [Array<RTSP::AbstractStream>] The list of streams associated with
    #   the session.
    attr_reader :streams

    attr_reader :state

    # The number of seconds before the session expires.  Defaults to 60.
    attr_reader :timeout

    # A session's state indicates where it's at in the process of sending or
    # receiving a stream.  Can be:
    # * :init
    #   * "The initial state, no valid SETUP has been received yet."
    # * :ready
    #   * "Last SETUP received was successful, reply sent or after playing, last
    #     PAUSE received was successful, reply sent.""
    # * :playing
    #   * "Last PLAY received was successful, reply sent.  Data is being sent.
    # * :recording
    #   * "The server is recording media data."
    attr_accessor :state

    def initialize
      @streams = []
      @id = Time.now.to_ntp.to_s
      @state = :init
      @timeout = 60
      @updated = Time.now
    end

=begin
    def setup(broadcast_type, send_on_port)
      if @state == :init
        @state = :ready
      end

      @stream.broadcast_type = broadcast_type
      @stream.client_rtp_port = send_on_port
      @stream.rtp_sender.setup_streamer
    end
=end

    def play
      unless @state == :ready
        return false
      end

      updated
      @state = :playing
      @streams.each(&:play)
    end

    def playing?
      @state == :playing
    end

    def pause
      updated
      @state = :ready
      @streams.each(&:pause)
    end

    def ready?
      @state == :ready
    end

    def record
      updated
      @state = :recording
      @streams.each(&:record)
    end

    def recording?
      @state == :recording
    end

    def expired?
      Time.now - @updated >= @timeout
    end

    # @todo Figure out lower transport for TCP
    # @todo interleave streams
    # @todo multiple streams
    # @todo setup listener for sever_port
    def transport_data(env)
      RTSP::Logger.log "Session transport info..."

      destination_address = env['rtsp.remote_address']
      requested = env['RTSP_TRANSPORT']

      transport = "#{transport_protocol};#{transport_address_type}"
      transport << ";destination=#{destination_address}"

      if transport_address_type == :multicast
        multicast_ports = requested[:port][:rtp], requested[:port][:rtcp] ||
          @streams.first.rtp_sender.rtp_port, @streams.first.rtp_sender.rtcp_port

        transport << ";ttl=4"
        transport << ";port=#{multicast_ports.first}-#{multicast_ports.last}"
      else
        rtp_port = requested[:client_port][:rtp] || @streams.first.rtp_sender.rtp_port
        rtcp_port = requested[:client_port][:rtcp] ||@streams.first.rtp_sender.rtcp_port

        transport << ";client_port=#{rtp_port}-#{rtcp_port}"
        transport << ";server_port=#{rtp_port}-#{rtcp_port}"
        transport << ";ssrc=#{@streams.first.rtp_sender.ssrc}"
      end

      transport
    end

    def transport_address_type
      ip_address_types = @streams.map(&:multicast?).map do |type|
        type == true ? :multicast : :unicast
      end.uniq

      unless ip_address_types.size == 1
        message = "Multiple transport IP address types specified for session.  "
        message << "Picking the first one: #{ip_address_types.first}"
        warn message
      end

      ip_address_types.first
    end

    def transport_protocol
      protocols = @streams.map(&:transport_protocol).uniq

      unless protocols.size == 1
        message = "Multiple transport protocols specified for session.  "
        message << "Picking the first one: #{protocol.first}"
        warn message
      end

      protocols.first
    end

    def start_cleanup_timer(expired_callback)
      @cleanup_callback ||= expired_callback

      @cleanup_timer = EventMachine::Timer.new(@timeout) do
        if expired?
          expired_callback.call(@id)
        else
          restart_cleanup_timer
        end
      end
    end

    def restart_cleanup_timer
      start_cleanup_timer(@cleanup_callback)
    end

    private

    def updated
      @updated = Time.now
      RTSP::Logger.log "Session #{@id} updated at #{@updated}"
      @cleanup_timer.cancel
      restart_cleanup_timer
    end
  end
end
