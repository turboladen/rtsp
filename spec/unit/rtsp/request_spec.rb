require 'spec_helper'
require 'rtsp/request'

describe RTSP::Request do
  RTSP::Request.instance_variable_get(:@method_types).each do |method|
    it "adds a User-Agent header to the #{method} method" do
      message = RTSP::Request.send(method, "rtsp://1.2.3.4/stream1")
      message.to_s.should include "User-Agent: RubyRTSP/"
    end
  end

  describe ".parse" do
    subject { RTSP::Request.parse(raw_request) }

    context "OPTIONS" do
      let(:raw_request) { OPTIONS_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.method_type.should == :options
        subject.body.should be_empty

        subject.rtsp_version.should == "1.0"
        subject.uri.should be_nil
        subject.headers[:cseq].should == 1
        subject.headers[:require].should == 'implicit-play'
        subject.headers[:proxy_require].should == 'gzipped-messages'
      end
    end

    context "DESCRIBE" do
      let(:raw_request) { DESCRIBE_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.method_type.should == :describe
        subject.body.should be_empty

        subject.rtsp_version.should == "1.0"
        subject.uri.should == "rtsp://server.example.com/fizzle/foo"
        subject.headers[:cseq].should == 312
        subject.headers[:accept].should ==
          "application/sdp, application/rtsl, application/mheg"
      end
    end

    context "ANNOUNCE" do
      let(:raw_request) { ANNOUNCE_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.method_type.should == :announce
        subject.body.should be_a SDP::Description

        subject.rtsp_version.should == "1.0"
        subject.uri.should == "rtsp://server.example.com/fizzle/foo"
        subject.headers[:cseq].should == 312
        subject.headers[:date].should == "23 Jan 1997 15:35:06 GMT"
        subject.headers[:session].should == { session_id: 47112344 }
        subject.headers[:content_type].should == "application/sdp"
        subject.headers[:content_length].should == 332
      end
    end

    context "SETUP" do
      let(:raw_request) { SETUP_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.method_type.should == :setup
        subject.body.should be_empty

        subject.rtsp_version.should == "1.0"
        subject.uri.should == "rtsp://example.com/foo/bar/baz.rm"
        subject.headers[:cseq].should == 302
        subject.headers[:transport].should == {
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
        subject.method_type.should == :play
        subject.body.should be_empty

        subject.rtsp_version.should == "1.0"
        subject.uri.should == "rtsp://audio.example.com/audio"
        subject.headers[:cseq].should == 835
        subject.headers[:session].should == { session_id: 12345678 }
        subject.headers[:range].should == "npt=10-15"
      end
    end

    context "PAUSE" do
      let(:raw_request) { PAUSE_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.method_type.should == :pause
        subject.body.should be_empty

        subject.rtsp_version.should == "1.0"
        subject.uri.should == "rtsp://example.com/fizzle/foo"
        subject.headers[:cseq].should == 834
        subject.headers[:session].should == { session_id: 12345678 }
      end
    end

    context "TEARDOWN" do
      let(:raw_request) { TEARDOWN_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.method_type.should == :teardown
        subject.body.should be_empty

        subject.rtsp_version.should == "1.0"
        subject.uri.should == "rtsp://example.com/fizzle/foo"
        subject.headers[:cseq].should == 892
        subject.headers[:session].should == { session_id: 12345678 }
      end
    end

    context "GET_PARAMETER" do
      let(:raw_request) { GET_PARAMETER_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.method_type.should == :get_parameter
        subject.body.should == "packets_received\r\njitter\r\n"

        subject.rtsp_version.should == "1.0"
        subject.uri.should == "rtsp://example.com/fizzle/foo"
        subject.headers[:cseq].should == 431
        subject.headers[:content_length].should == 15
        subject.headers[:session].should == { session_id: 12345678 }
      end
    end

    context "SET_PARAMETER" do
      let(:raw_request) { SET_PARAMETER_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.method_type.should == :set_parameter
        subject.body.should == "barparam: barstuff\r\n"

        subject.rtsp_version.should == "1.0"
        subject.uri.should == "rtsp://example.com/fizzle/foo"
        subject.headers[:cseq].should == 421
        subject.headers[:content_length].should == 20
      end
    end

    context "RECORD" do
      let(:raw_request) { RECORD_REQUEST }

      it "parses the request" do
        subject.should be_a RTSP::Request
        subject.method_type.should == :record
        subject.body.should be_empty

        subject.rtsp_version.should == "1.0"
        subject.uri.should == "rtsp://example.com/meeting/audio.en"
        subject.headers[:cseq].should == 954
        subject.headers[:session].should == { session_id: 12345678 }
        subject.headers[:conference].should == "128.16.64.19/32492374"
      end
    end
  end
end
