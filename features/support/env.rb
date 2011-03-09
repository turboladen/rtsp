require 'rubygems'
require 'socket'
require 'timeout'
require 'cucumber/rspec/doubles'

$:.unshift(File.dirname(__FILE__) + '/../../lib')
require 'rtsp/client'
require 'rtsp/request'

DESCRIBE_RESPONSE = %Q{ RTSP/1.0 200 OK\r
Server: DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )\r
Cseq: 1\r
Cache-Control: no-cache\r
Content-length: 406\r
Date: Sun, 23 Jan 2011 00:36:45 GMT\r
Expires: Sun, 23 Jan 2011 00:36:45 GMT\r
Content-Type: application/sdp\r
x-Accept-Retransmit: our-retransmit\r
x-Accept-Dynamic-Rate: 1\r
Content-Base: rtsp://64.202.98.91:554/gs.sdp/\r
\r\n\r
v=0\r
o=- 545877020 467920391 IN IP4 127.0.0.1\r
s=Groove Salad from SomaFM [aacPlus]\r
i=Downtempo Ambient Groove\r
c=IN IP4 0.0.0.0\r
t=0 0\r
a=x-qt-text-cmt:Orban Opticodec-PC\r\n
a=x-qt-text-nam:Groove Salad from SomaFM [aacPlus]\r
a=x-qt-text-inf:Downtempo Ambient Groove\r
a=control:*\r
m=audio 0 RTP/AVP 96\r
b=AS:48\r
a=rtpmap:96 MP4A-LATM/44100/2\r
a=fmtp:96 cpresent=0;config=400027200000\r
a=control:trackID=1\r
\r\n}

OPTIONS_RESPONSE = %Q{ RTSP/1.0 200 OK\r
CSeq: 1\r
Date: Fri, Jan 28 2011 01:14:42 GMT\r
Public: DESCRIBE, SETUP, TEARDOWN, PLAY, PAUSE\r
\r\n}

SETUP_RESPONSE = %Q{RTSP/1.0 200 OK\r
CSeq: 1\r
Date: Fri, Jan 28 2011 01:14:42 GMT\r
Transport: RTP/AVP;unicast;destination=10.221.222.186;source=10.221.222.235;client_port=9000-9001;server_port=6700-6701\r
Session: 118\r
\r\n}

TEARDOWN_RESPONSE = %Q{RTSP/1.0 200 OK\r
CSeq: 1\r
Server: DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )\r
Session: 8705595695936445582\r
Connection: Close\r
\r\n}

PLAY_RESPONSE = %Q{RTSP/1.0 200 OK\r
CSeq: 1\r
Date: Fri, Jan 28 2011 01:14:42 GMT\r
Range: npt=0.000-\r
Session: 118\r
RTP-Info: url=rtsp://10.221.222.235/stream1/track1;seq=17320;rtptime=400880602\r
\r\n}

RECORD_RESPONSE = %Q{RTSP/1.0 200 OK\r
CSeq: 1\r
\r\n}
