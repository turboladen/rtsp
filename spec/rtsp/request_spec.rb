require File.dirname(__FILE__) + '/../spec_helper'
require 'rtsp/request'
require 'sdp'

describe RTSP::Request do
  before do
    @stream = "rtsp://1.2.3.4/stream1"
  end

  context "should build an OPTIONS message" do
    it "with default sequence number" do
      message = RTSP::Request.execute(:options, @stream)
      message.should == "OPTIONS rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\r\n"
    end

    it "with passed-in sequence number" do
      message = RTSP::Request.execute(:options, @stream, :cseq => 2345)
      message.should == "OPTIONS rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 2345\r\n\r\n"
    end
  end

  context "should build a DESCRIBE message" do
    it "with default sequence and accept values" do
      message = RTSP::Request.execute(:describe, @stream)
      message.should include "DESCRIBE rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 1\r\n"
      message.should include "Accept: application/sdp\r\n"
      message.should include "\r\n\r\n"
    end

    it "with default sequence value" do
      message = RTSP::Request.execute(:describe, @stream, {
          :accept => 'application/sdp, application/rtsl'
      })
      message.should include "DESCRIBE rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 1\r\n"
      message.should include "Accept: application/sdp, application/rtsl\r\n"
      message.should include "\r\n\r\n"
    end

    it "with passed-in sequence and accept values" do
      message = RTSP::Request.execute(:describe, @stream, {
          :accept => 'application/sdp, application/rtsl',
          :cseq => 2345
      })
      message.should include "DESCRIBE rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 2345\r\n"
      message.should include "Accept: application/sdp, application/rtsl\r\n"
      message.should include "\r\n\r\n"
    end
  end

  context "should build a ANNOUNCE message" do
    it "with default sequence, content type, sdp, and content length values" do
      message = RTSP::Request.execute(:announce, @stream,
        :session => 123456789)

      message.should include "ANNOUNCE rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 1\r\n"
      message.should include "Session: 123456789\r\n"
      message.should include "Content-Type: application/sdp\r\n"
      message.should include "Content-Length: 25\r\n"
      message.should include "\r\n\r\nv=0\r\no=     \r\ns=\r\nt= \r\n\r\n"
    end

    it "with default sequence value" do
      message = RTSP::Request.execute(:announce, @stream,
                                              :session => 123456789,
                                              :content_type => 'application/sdp')

      message.should include "ANNOUNCE rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 1\r\n"
      message.should include "Session: 123456789\r\n"
      message.should include "Content-Type: application/sdp\r\n"
      message.should include "Content-Length: 25\r\n"
      message.should include "\r\n\r\nv=0\r\no=     \r\ns=\r\nt= \r\n\r\n"
    end

    it "with passed-in sequence, content-type values" do
      message = RTSP::Request.execute(:announce, @stream,
        { :session => 123456789,
          :content_type => 'application/sdp, application/rtsl',
          :cseq => 2345
      })

      message.should include "ANNOUNCE rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 2345\r\n"
      message.should include "Session: 123456789\r\n"
      message.should include "Content-Type: application/sdp, application/rtsl\r\n"
      message.should include "Content-Length: 25\r\n"
      message.should include "\r\n\r\nv=0\r\no=     \r\ns=\r\nt= \r\n\r\n"
    end

    it "with passed-in sequence, content-type, sdp description" do
      sdp = SDP::Description.new
      sdp.protocol_version = 1
      sdp.username = 'bobo'

      message = RTSP::Request.execute(:announce, @stream,
          { :session => 123456789,
          :content_type => 'application/sdp',
          :cseq => 2345
      }, sdp.to_s)

      message.should match /^ANNOUNCE rtsp/
      message.should include "ANNOUNCE rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 2345\r\n"
      message.should include "Session: 123456789\r\n"
      message.should include "Content-Type: application/sdp\r\n"
      message.should include "Content-Length: 29\r\n"
      message.should match /\r\n\r\nv=1\r\no=bobo     \r\ns=\r\nt= \r\n\r\n$/
    end
  end

  context "should build a SETUP message" do
    it "with default sequence, transport, client_port, and routing values" do
      message = RTSP::Request.execute(:setup, @stream)

      message.should match /^SETUP rtsp/
      message.should include "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 1\r\n"
      message.should include "Transport: RTP/AVP;unicast;client_port=9000-9001\r\n"
      message.should match /\r\n\r\n$/
    end

    it "with default sequence, transport, and client_port values" do
      message = RTSP::Request.execute(:setup, @stream,
          :transport => [ "RTP/AVP", "multicast", { :client_port => "9000-9001" }]
      )

      message.should match /^SETUP rtsp/
      message.should include "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 1\r\n"
      message.should include "Transport: RTP/AVP;multicast;client_port=9000-9001\r\n"
      message.should match /\r\n\r\n$/
    end

    it "with default transport, client_port, and routing values" do
      pending "Convert to use new style"
      message = RTSP::Request.execute(:setup, @stream, :cseq=> 2345)

      message.should match /^SETUP rtsp/
      message.should include "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 2345\r\n"
      message.should include "Transport: RTP/AVP;unicast;client_port=9000-9001\r\n\r\n"
      message.should include "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 2345\r\n\Transport: RTP/AVP;unicast;client_port=9000-9001\r\n\r\n"
      message.should include "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 2345\r\n\Transport: RTP/AVP;unicast;client_port=9000-9001\r\n\r\n"
      message.should include "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 2345\r\n\Transport: RTP/AVP;unicast;client_port=9000-9001\r\n\r\n"
      message.should match /\r\n\r\n$/
    end
  end

  context "should build a PLAY message" do
    it "with default sequence and range values" do
      message = RTSP::Request.execute(:play, @stream, { :session => 12345 })

      message.should include "PLAY rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 1\r\n"
      message.should include "Session: 12345\r\n"
      message.should include "Range: npt=0.000-\r\n"
      message.should include "\r\n\r\n"
    end
    it "with default sequence value" do
      message = RTSP::Request.execute(:play, @stream, { :session => 12345,
          :range => { :npt => "0.000-1.234" }
      })

      message.should include "PLAY rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 1\r\n"
      message.should include "Session: 12345\r\n"
      message.should include "Range: npt=0.000-1.234\r\n"
      message.should include "\r\n\r\n"
    end
  end

  def build_request_with headers
    RTSP::Request.new(:options, "http://localhost", headers)
  end

  context "#headers_to_s turns a Hash into an String of header strings" do
    it "single header, non-hyphenated name, hash value" do
      header = { :range => { :npt => "0.000-" } }
      request = build_request_with header

      string = request.headers_to_s(header)
      string.is_a?(String).should be_true
      string.should include "Range: npt=0.000-"
    end

    it "single header, hyphenated, non-hash value" do
      header = { :if_modified_since => "Sat, 29 Oct 1994 19:43:31 GMT" }
      request = build_request_with header

      string = request.headers_to_s(header)
      string.is_a?(String).should be_true
      string.should include "If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT"
    end

    it "two headers, mixed hyphenated, array & hash values" do
      headers = {
        :cache_control => ["no-cache", { :max_age => 12345 }],
        :content_type => ['application/sdp', 'application/x-rtsp-mh']
      }
      request = build_request_with headers

      string = request.headers_to_s(headers)
      string.is_a?(String).should be_true
      string.should include "Cache-Control: no-cache;max_age=12345"
      string.should include "Content-Type: application/sdp, application/x-rtsp-mh"
    end
  end
end