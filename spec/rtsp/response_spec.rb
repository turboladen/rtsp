require_relative '../spec_helper'
require 'rtsp/response'

describe RTSP::Response do
  describe "#initialize" do
    it "expects a non-nil string on" do
      lambda { RTSP::Response.new(nil) }.should raise_exception RTSP::Error
    end

    it "expects a non-empty string on" do
      lambda { RTSP::Response.new("") }.should raise_exception RTSP::Error
    end
  end

  describe "#parse_head" do
    pending
  end

  describe "#parse_body" do
    pending
  end

  describe "#to_s" do
    it "returns the text that was passed in" do
      response = RTSP::Response.new OPTIONS_RESPONSE
      response.to_s.should == OPTIONS_RESPONSE
    end
  end

  describe "#inspect" do
    before do
      @response = RTSP::Response.new OPTIONS_RESPONSE
    end

    it "contains the class name and object ID first" do
      @response.inspect.should match /^#<RTSP::Response:\d+/
    end

    it "begins with <# and ends with >" do
      @response.inspect.should match /^#<.*>$/
    end
  end

  describe "create_reader" do
    pending
  end

  context "options" do
    before do
      @response = RTSP::Response.new OPTIONS_RESPONSE
    end

    it "returns a 200 code" do
      @response.code.should == 200
    end

    it "returns 'OK' message" do
      @response.message.should == 'OK'
    end

    it "returns the date header" do
      @response.date.should == 'Fri, Jan 28 2011 01:14:42 GMT'
    end

    it "returns the supported methods in the Public header" do
      @response.public.should == 'OPTIONS, DESCRIBE, SETUP, TEARDOWN, PLAY, PAUSE'
    end
  end

  context "describe" do
    before do
      @response = RTSP::Response.new DESCRIBE_RESPONSE
    end

    it "returns a 200 code" do
      @response.code.should == 200
    end

    it "returns 'OK' message" do
      @response.message.should == "OK"
    end

    it "returns all header fields" do
      @response.server.should == "DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )"
      @response.cseq.should == 1
      @response.cache_control.should == "no-cache"
      @response.content_length.should == 406
      @response.date.should == "Sun, 23 Jan 2011 00:36:45 GMT"
      @response.expires.should == "Sun, 23 Jan 2011 00:36:45 GMT"
      @response.content_type.should == "application/sdp"
      @response.x_accept_retransmit.should == "our-retransmit"
      @response.x_accept_dynamic_rate.should == 1
      @response.content_base.should == "rtsp://64.202.98.91:554/gs.sdp/"
    end

    it "body is a parsed SDP::Description" do
      @response.body.should be_kind_of SDP::Description
      sdp_info = @response.body
      sdp_info.protocol_version.should == "0"
      sdp_info.name.should == "Groove Salad from SomaFM [aacPlus]"
    end
  end

  context "setup" do
    before do
      @response = RTSP::Response.new SETUP_RESPONSE
    end

    it "returns a 200 code" do
      @response.code.should == 200
    end

    it "returns 'OK' message" do
      @response.message.should == 'OK'
    end

    it "returns the date header" do
      @response.date.should == 'Fri, Jan 28 2011 01:14:42 GMT'
    end

    it "returns the supported transport" do
      @response.transport.should == 'RTP/AVP;unicast;destination=10.221.222.186;source=10.221.222.235;client_port=9000-9001;server_port=6700-6701'
    end

    it "returns the session" do
      @response.session.should == 118
    end
  end

  context "play" do
    before do
      @response = RTSP::Response.new PLAY_RESPONSE
    end

    it "returns a 200 code" do
      @response.code.should == 200
    end

    it "returns 'OK' message" do
      @response.message.should == 'OK'
    end

    it "returns the date header" do
      @response.date.should == 'Fri, Jan 28 2011 01:14:42 GMT'
    end

    it "returns the supported range" do
      @response.range.should == 'npt=0.000-'
    end

    it "returns the session" do
      @response.session.should == 118
    end

    it "returns the rtp_info" do
      @response.rtp_info.should == 'url=rtsp://10.221.222.235/stream1/track1;seq=17320;rtptime=400880602'
    end
  end

  context "teardown" do
    before do
      @response = RTSP::Response.new TEARDOWN_RESPONSE
    end

    it "returns a 200 code" do
      @response.code.should == 200
    end

    it "returns 'OK' message" do
      @response.message.should == 'OK'
    end

    it "returns the date header" do
      @response.date.should == 'Fri, Jan 28 2011 01:14:47 GMT'
    end
  end

  context "#parse_head" do
    before do
      @response = RTSP::Response.new OPTIONS_RESPONSE
    end

    it "extracts the RTSP version from the header" do
      @response.rtsp_version.should == "1.0"
    end

    it "extracts the response code from the header as a Fixnum" do
      @response.code.is_a?(Fixnum).should be_true
      @response.code.should == 200
    end

    it "extracts the response message from the header" do
      @response.message.should == "OK"
    end

    it "returns empty value string when header has no value" do
      response = RTSP::Response.new NO_CSEQ_VALUE_RESPONSE
      response.parse_head NO_CSEQ_VALUE_RESPONSE
      response.instance_variable_get(:@cseq).should == ""
    end
  end

  describe "#split_head_and_body_from" do
    it "splits responses with headers and no body" do
      response = RTSP::Response.new OPTIONS_RESPONSE
      head_and_body = response.split_head_and_body_from OPTIONS_RESPONSE
      head_and_body.first.should == %Q{ RTSP/1.0 200 OK\r\n
CSeq: 1\r\n
Date: Fri, Jan 28 2011 01:14:42 GMT\r\n
Public: OPTIONS, DESCRIBE, SETUP, TEARDOWN, PLAY, PAUSE\r\n
}
    end

    it "splits responses with headers and body" do
      response = RTSP::Response.new DESCRIBE_RESPONSE
      head_and_body = response.split_head_and_body_from DESCRIBE_RESPONSE
      head_and_body.first.should == %{RTSP/1.0 200 OK\r\n
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
}
      head_and_body.last.should == %{
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
    end
  end
end
