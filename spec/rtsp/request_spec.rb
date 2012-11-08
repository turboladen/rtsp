require 'spec_helper'
require 'rtsp/request'

describe RTSP::Request do
  describe ".parse" do
    subject { RTSP::Request.parse(raw_request) }

    context "OPTIONS" do
      let(:raw_request) do
        <<-REQUEST
OPTIONS * RTSP/1.0\r
CSeq: 1\r
Require: implicit-play\r
Proxy-Require: gzipped-messages\r
\r
        REQUEST
      end

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :options
        subject.body.should be_nil
        subject.raw_body.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.should_not respond_to :url
        subject.cseq.should == 1
        subject.require.should == 'implicit-play'
        subject.proxy_require.should == 'gzipped-messages'
      end
    end

    context "DESCRIBE" do
      let(:raw_request) do
        <<-REQUEST
DESCRIBE rtsp://server.example.com/fizzle/foo RTSP/1.0\r
CSeq: 312\r
Accept: application/sdp, application/rtsl, application/mheg\r
\r
        REQUEST
      end

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :describe
        subject.body.should be_nil
        subject.raw_body.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://server.example.com/fizzle/foo"
        subject.cseq.should == 312
        subject.accept.should == "application/sdp, application/rtsl, application/mheg"
      end
    end

    context "ANNOUNCE" do
      let(:raw_request) do
        <<-REQUEST
ANNOUNCE rtsp://server.example.com/fizzle/foo RTSP/1.0\r
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
        REQUEST
      end

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :announce
        subject.body.should be_a SDP::Description
        subject.raw_body.should_not be_empty

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://server.example.com/fizzle/foo"
        subject.cseq.should == 312
        subject.date.should == "23 Jan 1997 15:35:06 GMT"
        subject.session.should == { session_id: 47112344 }
        subject.content_type.should == "application/sdp"
        subject.content_length.should == 332
      end
    end

    context "SETUP" do
      let(:raw_request) do
        <<-REQUEST
SETUP rtsp://example.com/foo/bar/baz.rm RTSP/1.0\r
CSeq: 302\r
Transport: RTP/AVP;unicast;client_port=4588-4589\r
\r
        REQUEST
      end

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :setup
        subject.body.should be_nil
        subject.raw_body.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://example.com/foo/bar/baz.rm"
        subject.cseq.should == 302
        subject.transport.should == {
          streaming_protocol: 'RTP',
          profile: 'AVP',
          broadcast_type: 'unicast',
          client_port: {
            rtp: "4588", rtcp: "4589"
          }
        }
      end
    end

    context "PLAY" do
      let(:raw_request) do
        <<-REQUEST
PLAY rtsp://audio.example.com/audio RTSP/1.0\r
CSeq: 835\r
Session: 12345678\r
Range: npt=10-15\r
\r
        REQUEST
      end

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :play
        subject.body.should be_nil
        subject.raw_body.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://audio.example.com/audio"
        subject.cseq.should == 835
        subject.session.should == { session_id: 12345678 }
        subject.range.should == "npt=10-15"
      end
    end

    context "PAUSE" do
      let(:raw_request) do
        <<-REQUEST
PAUSE rtsp://example.com/fizzle/foo RTSP/1.0\r
CSeq: 834\r
Session: 12345678\r
\r
        REQUEST
      end

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :pause
        subject.body.should be_nil
        subject.raw_body.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://example.com/fizzle/foo"
        subject.cseq.should == 834
        subject.session.should == { session_id: 12345678 }
      end
    end

    context "TEARDOWN" do
      let(:raw_request) do
        <<-REQUEST
TEARDOWN rtsp://example.com/fizzle/foo RTSP/1.0\r
CSeq: 892\r
Session: 12345678\r
\r
        REQUEST
      end

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :teardown
        subject.body.should be_nil
        subject.raw_body.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://example.com/fizzle/foo"
        subject.cseq.should == 892
        subject.session.should == { session_id: 12345678 }
      end
    end

    context "GET_PARAMETER" do
      let(:raw_request) do
        <<-REQUEST
GET_PARAMETER rtsp://example.com/fizzle/foo RTSP/1.0\r
CSeq: 431\r
Content-Type: text/parameters\r
Session: 12345678\r
Content-Length: 15\r
\r
packets_received\r
jitter\r
        REQUEST
      end

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :get_parameter
        subject.body.should == "packets_received\r\njitter\r\n"
        subject.raw_body.should == subject.body

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://example.com/fizzle/foo"
        subject.cseq.should == 431
        subject.content_length.should == 15
        subject.session.should == { session_id: 12345678 }
      end
    end

    context "SET_PARAMETER" do
      let(:raw_request) do
        <<-REQUEST
SET_PARAMETER rtsp://example.com/fizzle/foo RTSP/1.0\r
CSeq: 421\r
Content-length: 20\r
Content-type: text/parameters\r
\r
barparam: barstuff\r
        REQUEST
      end

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :set_parameter
        subject.body.should == "barparam: barstuff\r\n"
        subject.raw_body.should == subject.body

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://example.com/fizzle/foo"
        subject.cseq.should == 421
        subject.content_length.should == 20
      end
    end

    context "RECORD" do
      let(:raw_request) do
        <<-REQUEST
RECORD rtsp://example.com/meeting/audio.en RTSP/1.0\r
CSeq: 954\r
Session: 12345678\r
Conference: 128.16.64.19/32492374\r
\r
        REQUEST
      end

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :record
        subject.body.should be_nil
        subject.raw_body.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://example.com/meeting/audio.en"
        subject.cseq.should == 954
        subject.session.should == { session_id: 12345678 }
        subject.conference.should == "128.16.64.19/32492374"
      end
    end
  end
end
