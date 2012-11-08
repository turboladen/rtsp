require_relative '../spec_helper'
require 'rtsp/response'

describe RTSP::Common do
  subject do
    Object.new.extend RTSP::Common
  end

  describe "#split_head_and_body_from" do
    it "splits responses with headers and no body" do
      head_and_body = subject.split_head_and_body_from OPTIONS_RESPONSE
      head_and_body.first.should == %Q{RTSP/1.0 200 OK\r
CSeq: 1\r
Date: Fri, Jan 28 2011 01:14:42 GMT\r
Public: OPTIONS, DESCRIBE, SETUP, TEARDOWN, PLAY, PAUSE\r
}
    end

    it "splits responses with headers and body" do
      head_and_body = subject.split_head_and_body_from DESCRIBE_RESPONSE
      head_and_body.first.should == %{RTSP/1.0 200 OK\r
Server: DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )\r
Cseq: 1\r
Cache-Control: no-cache\r
Content-length: 406\r
Date: Sun, 23 Jan 2011 00:36:45 GMT\r
Expires: Sun, 23 Jan 2011 00:36:45 GMT\r
Content-Type: application/sdp\r
x-Accept-Retransmit: our-retransmit\r
x-Accept-Dynamic-Rate: 1\r
Content-Base: rtsp://64.202.98.91:554/gs.sdp/}

      head_and_body.last.should == %{\r
v=0\r
o=- 545877020 467920391 IN IP4 127.0.0.1\r
s=Groove Salad from SomaFM [aacPlus]\r
i=Downtempo Ambient Groove\r
c=IN IP4 0.0.0.0\r
t=0 0\r
a=x-qt-text-cmt:Orban Opticodec-PC\r
a=x-qt-text-nam:Groove Salad from SomaFM [aacPlus]\r
a=x-qt-text-inf:Downtempo Ambient Groove\r
a=control:*\r
m=audio 0 RTP/AVP 96\r
b=AS:48\r
a=rtpmap:96 MP4A-LATM/44100/2\r
a=fmtp:96 cpresent=0;config=400027200000\r
a=control:trackID=1\r
}
    end
  end

  describe "#parse_head_to_attrs" do
    before { subject.stub(:extract_status_line) }

    context "Session header contains session-id and timeout" do
      it "creates a :session reader with value being a Hash with key/value" do
        subject.parse_head_to_attrs(SETUP_RESPONSE_WITH_SESSION_TIMEOUT)
        subject.should respond_to :session
        subject.session.should == { session_id: 118, timeout: 49 }
      end
    end

    context "Session header contains just session-id" do
      it "creates a :session reader with value being a Hash with key/value" do
        subject.parse_head_to_attrs(SETUP_RESPONSE)
        subject.session.should == { session_id: 118 }
      end
    end

    context "header has no value" do
      it "returns empty value string" do
        subject.parse_head_to_attrs NO_CSEQ_VALUE_RESPONSE
        subject.instance_variable_get(:@cseq).should == ""
      end
    end
  end

  describe "#parse_body" do
    it "returns the text that was passed to it but with line feeds removed" do
      string = "hi\r\nguys\r\n\r\n"
      body = subject.parse_body string
      body.should be_a String
      body.should == string
    end

    context "@content_type is 'application/sdp'" do
      let(:description) do
        sdp = SDP::Description.new
        sdp.username = "me"
        sdp.id = 12345
        sdp.version = 12345
        sdp.network_type = "IN"
        sdp.address_type = "IP4"

        sdp
      end

      it "returns an SDP::Description" do
        subject.instance_variable_set(:@content_type, 'application/sdp')
        body = subject.parse_body description.to_s
        body.should be_a SDP::Description
        body.username.should == "me"
      end
    end
  end

  describe "#to_s" do
    context "@new_response and @new_request are not set" do
      specify { subject.to_s.should == "" }
    end

    context "@new_response or @new_request is set" do
      it "returns the text that was passed in" do
        response = subject.instance_variable_set(:@new_response, OPTIONS_RESPONSE)
        response.to_s.should == OPTIONS_RESPONSE
      end
    end
  end

  describe "#inspect" do
    it "contains the class name and object ID first" do
      subject.inspect.should match(/^#<#{subject.class}:\d+/)
    end

    it "contains the instance variables" do
      subject.instance_variable_set(:@test, 'pants')
      subject.inspect.should match(/@test="pants"/)
    end

    it "begins with <# and ends with >" do
      subject.inspect.should match(/^#<.*>$/)
    end
  end

  describe "#create_reader" do
    before do
      subject.send(:create_reader, 'make_noise', 'meow')
    end

    it "sets an instance variable by 'name' to 'value'" do
      subject.instance_variable_get(:@make_noise).should == 'meow'
    end

    it "defines a method for reading the instance variable" do
      subject.should respond_to :make_noise
      subject.make_noise.should == 'meow'
    end
  end
end
