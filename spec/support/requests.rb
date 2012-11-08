OPTIONS_REQUEST =
  %Q{OPTIONS * RTSP/1.0\r
CSeq: 1\r
Require: implicit-play\r
Proxy-Require: gzipped-messages\r
\r
}

DESCRIBE_REQUEST =
  %Q{DESCRIBE rtsp://server.example.com/fizzle/foo RTSP/1.0\r
CSeq: 312\r
Accept: application/sdp, application/rtsl, application/mheg\r
\r
}


ANNOUNCE_REQUEST =
  %Q{ANNOUNCE rtsp://server.example.com/fizzle/foo RTSP/1.0\r
CSeq: 312\r
Date: 23 Jan 1997 15:35:06 GMT\r
Session: 47112344\r
Content-Type: application/sdp\r
Content-Length: 332\r
\r
v=0\r
o=mhandley 2890844526 2890845468 IN IP4 126.16.64.4\r
s=SDP Seminar\r
i=A Seminar on the session description protocol\r
u=http://www.cs.ucl.ac.uk/staff/M.Handley/sdp.03.ps\r
e=mjh@isi.edu (Mark Handley)\r
c=IN IP4 224.2.17.12/127\r
t=2873397496 2873404696\r
a=recvonly\r
m=audio 3456 RTP/AVP 0\r
m=video 2232 RTP/AVP 31\r
}

SETUP_REQUEST =
  %Q{SETUP rtsp://example.com/foo/bar/baz.rm RTSP/1.0\r
CSeq: 302\r
Transport: RTP/AVP;unicast;client_port=4588-4589\r
\r
}

PLAY_REQUEST =
  %Q{PLAY rtsp://audio.example.com/audio RTSP/1.0\r
CSeq: 835\r
Session: 12345678\r
Range: npt=10-15\r
\r
}

PAUSE_REQUEST =
  %Q{PAUSE rtsp://example.com/fizzle/foo RTSP/1.0\r
CSeq: 834\r
Session: 12345678\r
\r
}

TEARDOWN_REQUEST =
  %Q{TEARDOWN rtsp://example.com/fizzle/foo RTSP/1.0\r
CSeq: 892\r
Session: 12345678\r
\r
}

GET_PARAMETER_REQUEST =
  %Q{GET_PARAMETER rtsp://example.com/fizzle/foo RTSP/1.0\r
CSeq: 431\r
Content-Type: text/parameters\r
Session: 12345678\r
Content-Length: 15\r
\r
packets_received\r
jitter\r
}

SET_PARAMETER_REQUEST =
  %Q{SET_PARAMETER rtsp://example.com/fizzle/foo RTSP/1.0\r
CSeq: 421\r
Content-length: 20\r
Content-type: text/parameters\r
\r
barparam: barstuff\r
}

RECORD_REQUEST =
  %Q{RECORD rtsp://example.com/meeting/audio.en RTSP/1.0\r
CSeq: 954\r
Session: 12345678\r
Conference: 128.16.64.19/32492374\r
\r
}
