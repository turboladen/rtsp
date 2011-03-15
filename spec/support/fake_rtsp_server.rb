require 'time'

class FakeRTSPServer
  def initialize(*args)
  end

  def send(*args)
    message = args.first
    message =~ /^(\w+).+CSeq: (\S+)/m
    @message_type = $1.downcase
    @cseq = $2
    @session = 1234567890
  end

  def recvfrom(size)
    response = eval @message_type
    [response]
  end

  def options
    message = "RTSP/1.0 200/OK\r\n"
    message << "CSeq: #{@cseq}\r\n"
    message << "Date: #{Time.now.httpdate}\r\n"
    message << "Public: DESCRIBE, SETUP, TEARDOWN, PLAY, PAUSE\r\n"
    message << "\r\n"
  end

  def describe
    message = "RTSP/1.0 200/OK\r\n"
    message << "CSeq: #{@cseq}\r\n"
    message << "Server: DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )\r\n"
    message << "Cache-Control: no-cache\r\n"
    message << "Content-length: 380\r\n"
    message << "Date: Tue, 15 Mar 2011 01:28:57 GMT\r\n"
    message << "Expires: Tue, 15 Mar 2011 01:28:57 GMT\r\n"
    message << "Content-Type: application/sdp\r\n"
    message << "x-Accept-Retransmit: our-retransmit\r\n"
    message << "x-Accept-Dynamic-Rate: 1\r\n"
    message << "Content-Base: rtsp://64.202.98.91:554/sa.sdp/\r\n"
    message << "\r\n"
    message << "v=\r\n"
    message << "o=- 1905836198 1274535354 IN IP4 127.0.0.\r\n"
    message << "s=Secret Agent from SomaF\r\n"
    message << "i=Downtempo Spy Loung\r\n"
    message << "c=IN IP4 0.0.0.\r\n"
    message << "t=0 \r\n"
    message << "a=x-qt-text-cmt:Orban Opticodec-P\r\n"
    message << "a=x-qt-text-nam:Secret Agent from SomaF\r\n"
    message << "a=x-qt-text-inf:Downtempo Spy Loung\r\n"
    message << "a=control:\r\n"
    message << "m=audio 0 RTP/AVP 9\r\n"
    message << "b=AS:4\r\n"
    message << "a=rtpmap:96 MP4A-LATM/44100/\r\n"
    message << "a=fmtp:96 cpresent=0;config=40002720000\r\n"
    message << "a=control:trackID=\r\n"
    message << "\r\n"
  end

  def setup
    %Q{RTSP/1.0 200 OK\r
CSeq: #{@cseq}\r
Date: #{Time.now.httpdate}\r
Transport: RTP/AVP;unicast;destination=10.221.222.186;source=10.221.222.235;client_port=9000-9001;server_port=6700-6701\r
Session: #{@session}\r
\r\n}
  end

  def play
    %Q{RTSP/1.0 200 OK\r
CSeq: #{@cseq}\r
Date: #{Time.now.httpdate}\r
Range: npt=0.000-\r
Session: #{@session}\r
RTP-Info: url=rtsp://10.221.222.235/stream1/track1;seq=17320;rtptime=400880602\r
\r\n}
  end

  def pause
    %Q{ RTSP/1.0 200 OK\r
CSeq: #{@cseq}\r
Date: #{Time.now.httpdate}\r
\r\n}
  end

  def teardown
    %Q{RTSP/1.0 200 OK\r
CSeq: #{@cseq}\r
Server: DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )\r
Session: #{@session}\r
Connection: Close\r
\r\n}
  end

  def record
    %Q{RTSP/1.0 200 OK\r
CSeq: #{@cseq}\r
\r\n}
  end
end