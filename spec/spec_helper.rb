require 'simplecov'

SimpleCov.start do
  add_filter "/spec/"
end

require 'rspec'
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'rtsp'

OPTIONS_RESPONSE = %Q{ RTSP/1.0 200 OK\r\n
CSeq: 1\r\n
Date: Fri, Jan 28 2011 01:14:42 GMT\r\n
Public: OPTIONS, DESCRIBE, SETUP, TEARDOWN, PLAY, PAUSE\r\n
}

DESCRIBE_RESPONSE = %{RTSP/1.0 200 OK\r\n
Server: DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )\r\n
Cseq: 1\r\n
Cache-Control: no-cache\r\n
Content-length: 406\r\n
Date: Sun, 23 Jan 2011 00:36:45 GMT\r\n
Expires: Sun, 23 Jan 2011 00:36:45 GMT\r\n
Content-Type: application/sdp\r\n
x-Accept-Retransmit: our-retransmit\r\n
x-Accept-Dynamic-Rate: 1\r\n
Content-Base: rtsp://64.202.98.91:554/gs.sdp/\r\n
\r\n\r\n
v=0
o=- 545877020 467920391 IN IP4 127.0.0.1
s=Groove Salad from SomaFM [aacPlus]
i=Downtempo Ambient Groove
c=IN IP4 0.0.0.0
t=0 0
a=x-qt-text-cmt:Orban Opticodec-PC
a=x-qt-text-nam:Groove Salad from SomaFM [aacPlus]
a=x-qt-text-inf:Downtempo Ambient Groove
a=control:*
m=audio 0 RTP/AVP 96
b=AS:48
a=rtpmap:96 MP4A-LATM/44100/2
a=fmtp:96 cpresent=0;config=400027200000
a=control:trackID=1
}

SETUP_RESPONSE = %Q{RTSP/1.0 200 OK\r\n
CSeq: 1\r\n
Date: Fri, Jan 28 2011 01:14:42 GMT\r\n
Transport: RTP/AVP;unicast;destination=10.221.222.186;source=10.221.222.235;client_port=9000-9001;server_port=6700-6701\r\n
Session: 118\r\n
\r\n}

PLAY_RESPONSE = %Q{RTSP/1.0 200 OK\r\n
CSeq: 1\r\n
Date: Fri, Jan 28 2011 01:14:42 GMT\r\n
Range: npt=0.000-\r\n
Session: 118\r\n
RTP-Info: url=rtsp://10.221.222.235/stream1/track1;seq=17320;rtptime=400880602\r\n
\r\n}

TEARDOWN_RESPONSE = %Q{RTSP/1.0 200 OK\r\n
CSeq: 1\r\n
Date: Fri, Jan 28 2011 01:14:47 GMT\r\n
\r\n}

NO_CSEQ_VALUE_RESPONSE = %Q{ RTSP/1.0 460 Only Aggregate Option Allowed\r\n
Server: DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )\r\n
Cseq: \r\n
Connection: Close\r\n
\r\n}
