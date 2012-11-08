require 'spec_helper'
require 'rtsp/request'

describe RTSP::Request do
  describe ".parse" do
    subject { RTSP::Request.parse(raw_request) }

    context "OPTIONS" do
      let(:raw_request) { OPTIONS_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :options
        subject.body.should be_nil
        subject.raw.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.url.should be_nil
        subject.cseq.should == 1
        subject.require.should == 'implicit-play'
        subject.proxy_require.should == 'gzipped-messages'
      end
    end

    context "DESCRIBE" do
      let(:raw_request) { DESCRIBE_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :describe
        subject.body.should be_nil
        subject.raw.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://server.example.com/fizzle/foo"
        subject.cseq.should == 312
        subject.accept.should == "application/sdp, application/rtsl, application/mheg"
      end
    end

    context "ANNOUNCE" do
      let(:raw_request) { ANNOUNCE_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :announce
        subject.body.should be_a SDP::Description
        subject.raw.should_not be_empty

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
      let(:raw_request) { SETUP_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :setup
        subject.body.should be_nil
        subject.raw.should be_nil

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
      let(:raw_request) { PLAY_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :play
        subject.body.should be_nil
        subject.raw.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://audio.example.com/audio"
        subject.cseq.should == 835
        subject.session.should == { session_id: 12345678 }
        subject.range.should == "npt=10-15"
      end
    end

    context "PAUSE" do
      let(:raw_request) { PAUSE_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :pause
        subject.body.should be_nil
        subject.raw.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://example.com/fizzle/foo"
        subject.cseq.should == 834
        subject.session.should == { session_id: 12345678 }
      end
    end

    context "TEARDOWN" do
      let(:raw_request) { TEARDOWN_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :teardown
        subject.body.should be_nil
        subject.raw.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://example.com/fizzle/foo"
        subject.cseq.should == 892
        subject.session.should == { session_id: 12345678 }
      end
    end

    context "GET_PARAMETER" do
      let(:raw_request) { GET_PARAMETER_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :get_parameter
        subject.body.should == "packets_received\r\njitter\r\n"
        subject.raw.should == raw_request

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://example.com/fizzle/foo"
        subject.cseq.should == 431
        subject.content_length.should == 15
        subject.session.should == { session_id: 12345678 }
      end
    end

    context "SET_PARAMETER" do
      let(:raw_request) { SET_PARAMETER_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :set_parameter
        subject.body.should == "barparam: barstuff\r\n"
        subject.raw.should == raw_request

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://example.com/fizzle/foo"
        subject.cseq.should == 421
        subject.content_length.should == 20
      end
    end

    context "RECORD" do
      let(:raw_request) { RECORD_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.action.should == :record
        subject.body.should be_nil
        subject.raw.should be_nil

        subject.rtsp_version.should == "1.0"
        subject.url.should == "rtsp://example.com/meeting/audio.en"
        subject.cseq.should == 954
        subject.session.should == { session_id: 12345678 }
        subject.conference.should == "128.16.64.19/32492374"
      end
    end
  end
end
