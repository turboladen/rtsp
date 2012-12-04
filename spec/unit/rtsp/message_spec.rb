require 'sdp'
require 'spec_helper'
require 'rtsp/message'


describe RTSP::Message do
  let(:stream) { "rtsp://1.2.3.4/stream1" }

  describe "#header" do
    it "raises if the header type isn't a String" do
      expect { subject.header :hi, "everyone" }.to raise_error RTSP::Error
    end
  end

  describe "#with_headers" do
    it "calls #add_headers and returns an RTSP::Message" do
      new_headers = { 'Test' => 'test' }
      subject.should_receive(:add_headers).with(new_headers)

      result = subject.with_headers('Test' => "test")
      result.should be_a RTSP::Message
    end
  end

  describe "#with_headers_and_body" do
    it "returns an RTSP::Message" do
      new_headers_and_body = { 'Test' => 'test', body: 'the body' }
      subject.should_receive(:with_headers).with('Test' => 'test')
      subject.should_receive(:with_body).with('the body')

      result = subject.with_headers_and_body(new_headers_and_body)
      result.should be_a RTSP::Message
    end
  end

  describe "#with_body" do
    let(:new_body) { "1234567890" }
    before { subject.with_body(new_body) }

    it "adds the passed-in text to the body of the message" do
      subject.body.should == new_body
    end

    it "adds the Content-Length header to reflect the body" do
      subject.headers['Content-Length'].should == new_body.size
    end
  end

  describe "#message" do
    before do
      headers = double "@headers"
      headers.stub(:to_headers_s).and_return "some headers\r\n"
      subject.instance_variable_set(:@headers, headers)
      subject.stub(:status_line).and_return "test status\r\n"
    end

    context "@body is empty" do
      it "builds the headers into the message" do
        subject.send(:message).should == %Q{test status\r
some headers\r
\r
}
      end
    end

    context "@body is set" do
      it "builds the headers and body into the message" do
        subject.instance_variable_set(:@body, "this is my body")
        subject.send(:message).should == %Q{test status\r
some headers\r
\r
this is my body}
      end
    end
  end

  describe "#split_head_and_body_from" do
    it "splits responses with headers and no body" do
      head_and_body = subject.split_head_and_body_from OPTIONS_RESPONSE
      head_and_body.first.should == %Q{RTSP/1.0 200 OK\r
CSeq: 1\r
Date: Fri, Jan 28 2011 01:14:42 GMT\r
Public: OPTIONS, DESCRIBE, SETUP, TEARDOWN, PLAY, PAUSE}
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
\r
}
    end
  end

  describe "#parse_head" do
    before { subject.stub(:extract_status_line) }

    context "Session header contains session-id and timeout" do
      it "creates a :session reader with value being a Hash with key/value" do
        subject.parse_head(SETUP_RESPONSE_WITH_SESSION_TIMEOUT)
        subject.headers.should have_key 'Session'
        subject.headers['Session'].should == { session_id: 118, timeout: 49 }
      end
    end

    context "Session header contains just session-id" do
      it "creates a :session reader with value being a Hash with key/value" do
        subject.parse_head(SETUP_RESPONSE)
        subject.headers['Session'].should == { session_id: 118 }
      end
    end

    context "header uses Cseq instead of CSeq" do
      it "converts the header name to CSeq" do
        subject.parse_head(NO_CSEQ_VALUE_RESPONSE)
        subject.headers.should have_key 'CSeq'
        subject.headers.should_not have_key 'Cseq'
      end
    end

    context "header has no value" do
      it "returns empty value string" do
        subject.parse_head(NO_CSEQ_VALUE_RESPONSE)
        subject.headers['CSeq'].should == ""
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

    context "@headers[:content_type] is 'application/sdp'" do
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
        subject.instance_variable_set(:@headers, { 'Content-Type' => 'application/sdp' })
        body = subject.parse_body description.to_s
        body.should be_a SDP::Description
        body.username.should == "me"
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
end
