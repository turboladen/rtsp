require 'spec_helper'
require 'rtsp/response'

describe RTSP::Response do
  describe ".parse" do
    subject { RTSP::Response.parse(raw_response) }

    context "OPTIONS" do
      let(:raw_response) { OPTIONS_RESPONSE }

      it "parses the response" do
        subject.should be_ok
        subject.body.should be_empty

        subject.headers[:cseq].should == 1
        subject.headers[:date].should == "Fri, Jan 28 2011 01:14:42 GMT"
        subject.headers[:public].should == "OPTIONS, DESCRIBE, SETUP, TEARDOWN, PLAY, PAUSE"
      end
    end

    context "DESCRIBE" do
      let(:raw_response) { DESCRIBE_RESPONSE }

      it "parses the response" do
        subject.should be_ok
        subject.body.should be_a SDP::Description

        subject.headers[:server].should == "DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )"
        subject.headers[:cseq].should == 1
        subject.headers[:cache_control].should == 'no-cache'
        subject.headers[:date].should == "Sun, 23 Jan 2011 00:36:45 GMT"
        subject.headers[:expires].should == "Sun, 23 Jan 2011 00:36:45 GMT"
        subject.headers[:content_type].should == 'application/sdp'
        subject.headers[:x_accept_retransmit].should == 'our-retransmit'
        subject.headers[:x_accept_dynamic_rate].should == 1
        subject.headers[:content_base].should == "rtsp://64.202.98.91:554/gs.sdp/"
      end
    end

    context "SETUP" do
      let(:raw_response) { SETUP_RESPONSE }

      it "parses the response" do
        subject.should be_ok
        subject.body.should be_empty

        subject.headers[:cseq].should == 1
        subject.headers[:date].should == "Fri, Jan 28 2011 01:14:42 GMT"
        subject.headers[:transport][:streaming_protocol].should == "RTP"
        subject.headers[:transport][:profile].should == "AVP"
        subject.headers[:transport][:broadcast_type].should == "unicast"
        subject.headers[:transport][:destination].should == "10.221.222.186"
        subject.headers[:transport][:source].should == "10.221.222.235"
        subject.headers[:transport][:client_port][:rtp].should == "9000"
        subject.headers[:transport][:client_port][:rtcp].should == "9001"
        subject.headers[:session].should == { session_id: 118 }
      end
    end

    context "PLAY" do
      let(:raw_response) { PLAY_RESPONSE }

      it "parses the response" do
        subject.should be_ok
        subject.body.should be_empty

        subject.headers[:cseq].should == 1
        subject.headers[:date].should == "Fri, Jan 28 2011 01:14:42 GMT"
        subject.headers[:range].should == "npt=0.000-"
        subject.headers[:session].should == { session_id: 118 }
        subject.headers[:rtp_info].should ==
          "url=rtsp://10.221.222.235/stream1/track1;seq=17320;rtptime=400880602"
      end
    end

    context "TEARDOWN" do
      let(:raw_response) { TEARDOWN_RESPONSE }

      it "parses the response" do
        subject.should be_ok
        subject.body.should be_empty

        subject.headers[:cseq].should == 1
        subject.headers[:date].should == "Fri, Jan 28 2011 01:14:47 GMT"
      end
    end

    context "header value doesn't exist" do
      let(:raw_response) { NO_CSEQ_VALUE_RESPONSE }

      it "parses the value to be empty" do
        subject.headers[:cseq].should be_empty
      end
    end
  end

  describe "#extract_status_line" do
    let(:status_line) { "RTSP/1.0 200 OK" }
    before { subject.extract_status_line(status_line) }

    it "extracts the rtsp version" do
      subject.rtsp_version.should == "1.0"
    end

    it "extracts the response code from the header as a Fixnum" do
      subject.code.should == 200
    end

    it "extracts the response message from the header" do
      subject.status_message.should == "OK"
    end

    it "raises when RTSP version is corrupted" do
      expect { subject.extract_status_line "RTSP/ 200 OK\r\n" }.to raise_error RTSP::Error
    end

    it "raises when the response code is corrupted" do
      expect { subject.extract_status_line "RTSP/1.0 2 OK\r\n" }.to raise_error RTSP::Error
    end

    it "raises when the response message is corrupted" do
      expect { subject.extract_status_line "RTSP/1.0 200 \r\n" }.to raise_error RTSP::Error
    end
  end
end
