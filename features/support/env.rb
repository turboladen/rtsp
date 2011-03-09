require 'rubygems'
require 'socket'
require 'timeout'
require 'cucumber/rspec/doubles'

$:.unshift(File.dirname(__FILE__) + '/../../lib')
require 'rtsp/client'
require 'rtsp/request'

DESCRIBE_RESPONSE = <<-RESP
RTSP/1.0 200 OK
Server: DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )
Cseq: 1
Cache-Control: no-cache
Content-length: 406
Date: Sun, 23 Jan 2011 00:36:45 GMT
Expires: Sun, 23 Jan 2011 00:36:45 GMT
Content-Type: application/sdp
x-Accept-Retransmit: our-retransmit
x-Accept-Dynamic-Rate: 1
Content-Base: rtsp://64.202.98.91:554/gs.sdp/

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
RESP

OPTIONS_RESPONSE = <<-RESP
RTSP/1.0 200 OK
CSeq: 1
Public: DESCRIBE, SETUP, TEARDOWN, PLAY, PAUSE
RESP
