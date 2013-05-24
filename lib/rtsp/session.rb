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

    def setup
      @state = :ready
    end

    def play(start_time, stop_time)
      unless @state == :ready
        return false
      end

      updated
      @state = :playing
      @streams.each { |stream| stream.play(start_time, stop_time) }
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
