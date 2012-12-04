require_relative '../ext/time_ext'


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

    # The identifier that labels this session.
    attr_reader :session_id

    attr_reader :path

    # @return [RTSP::AbstractStream]
    attr_reader :stream

    attr_reader :state

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
      @stream = nil
      @session_id = Time.now.to_ntp
      @state = :init
      @path = ''
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

      @stream.play
    end

    def pause
      @stream.pause
    end
  end
end
