class RTSPClient
  class RequestMessages
    def initialize
      @RTSP_VER = "RTSP/1.0"
      @RTSP_ACCEPT_TYPE = "application/sdp"
      @RTP_DEFAULT_PORT = 9000
      @RTP_DEFAULT_PACKET_TYPE = "RTP/AVP"
      @RTP_DEFAULT_ROUTING = "unicast"
      @RTSP_DEFAULT_SEQUENCE_NUMBER = 1
      @RTSP_DEFAULT_NPT = "0.000-"
    end

    def options(stream, options={})
      options[:sequence] ||= @RTSP_DEFAULT_SEQUENCE_NUMBER
      message =  "OPTIONS #{stream} #{@RTSP_VER}\r\n"
      message << "CSeq: #{options[:sequence]}\r\n\r\n"
    end

    def describe(stream, options={})
      options[:sequence] ||= @RTSP_DEFAULT_SEQUENCE_NUMBER
      options[:accept]   ||= @RTSP_ACCEPT_TYPE
      message =  "DESCRIBE #{stream} #{@RTSP_VER}\r\n"
      message << "CSeq: #{options[:sequence]}\r\n"
      message << "Accept: #{options[:accept]}\r\n\r\n"
    end

    def setup(track, options={})
      options[:sequence]    ||= @RTSP_DEFAULT_SEQUENCE_NUMBER
      options[:transport]   ||= @RTP_DEFAULT_PACKET_TYPE
      options[:port]        ||= @RTP_DEFAULT_PORT
      options[:routing] ||= @RTP_DEFAULT_ROUTING
      message =  "SETUP #{track} #{@RTSP_VER}\r\n"
      message << "CSeq: #{options[:sequence]}\r\n"
      message << "Transport: #{options[:transport]};"
      message <<            "#{options[:destination]};"
      message <<            "client_port=#{options[:port]}-#{options[:port]+1}\r\n\r\n"
    end

    def play(stream, session, options={})
      options[:sequence] ||= @RTSP_DEFAULT_SEQUENCE_NUMBER
      options[:npt] ||= @RTSP_DEFAULT_NPT
      message =  "PLAY #{stream} #{@RTSP_VER}\r\n"
      message << "CSeq: #{options[:sequence]}\r\n"
      message << "Session: #{session}\r\n"
      message << "Range: npt=#{options[:npt]}\r\n\r\n"
    end

    def teardown(stream, session, options={})
      options[:sequence] ||= @RTSP_DEFAULT_SEQUENCE_NUMBER
      message =  "TEARDOWN #{stream} #{@RTSP_VER}\r\n"
      message << "CSeq: #{options[:sequence]}\r\n"
      message << "Session: #{session}\r\n\r\n"
    end
  end
end
