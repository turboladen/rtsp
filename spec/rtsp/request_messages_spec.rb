require File.dirname(__FILE__) + '/../spec_helper'
require 'rtsp/request_messages'
require 'sdp'

describe RTSP::RequestMessages do
  include RTSP::RequestMessages

  before do
    @stream = "rtsp://1.2.3.4/stream1"
  end

  context "should build an OPTIONS message" do
    it "with default sequence number" do
      message = RTSP::RequestMessages.options @stream
      message.should == "OPTIONS rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\r\n"
    end

    it "with passed-in sequence number" do
      message = RTSP::RequestMessages.options(@stream, 2345)
      message.should == "OPTIONS rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 2345\r\n\r\n"
    end
  end

  context "should build a DESCRIBE message" do
    it "with default sequence and accept values" do
      message = RTSP::RequestMessages.describe @stream
      message.should == "DESCRIBE rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Accept: application/sdp\r\n\r\n"
    end

    it "with default sequence value" do
      message = RTSP::RequestMessages.describe(@stream, {
          :accept => ['application/sdp', 'application/rtsl']
      })
      message.should == "DESCRIBE rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Accept: application/sdp, application/rtsl\r\n\r\n"
    end

    it "with passed-in sequence and accept values" do
      message = RTSP::RequestMessages.describe(@stream, {
        :accept => ['application/sdp', 'application/rtsl'],
        :sequence => 2345
      })
      message.should == "DESCRIBE rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 2345\r\n\Accept: application/sdp, application/rtsl\r\n\r\n"
    end
  end

  context "should build a ANNOUNCE message" do
    it "with default sequence, content type, sdp, and content length values" do
      message = RTSP::RequestMessages.announce(@stream, 123456789)
      message.should == "ANNOUNCE rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Date: \r\nSession: 123456789\r\nContent-Type: application/sdp\r\nContent-Length: 25\r\n\r\nv=0\r\no=     \r\ns=\r\nt= \r\n\r\n"
    end

    it "with default sequence value" do
      message = RTSP::RequestMessages.announce(@stream, 123456789,
        :content_type => 'application/sdp')
      message.should == "ANNOUNCE rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Date: \r\nSession: 123456789\r\nContent-Type: application/sdp\r\nContent-Length: 25\r\n\r\nv=0\r\no=     \r\ns=\r\nt= \r\n\r\n"
    end

    it "with passed-in sequence, content-type values" do
      message = RTSP::RequestMessages.announce(@stream, 123456789, {
          :content_type => 'application/sdp',
          :sequence => 2345
      })
      message.should == "ANNOUNCE rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 2345\r\n\Date: \r\nSession: 123456789\r\nContent-Type: application/sdp\r\nContent-Length: 25\r\n\r\nv=0\r\no=     \r\ns=\r\nt= \r\n\r\n"
    end

    it "with passed-in sequence, content-type, sdp values" do
      sdp = SDP::Description.new
      sdp.protocol_version = 1
      sdp.username = 'bobo'

      message = RTSP::RequestMessages.announce(@stream, 123456789, {
        :content_type => 'application/sdp',
        :sequence => 2345,
        :sdp => sdp
      })
      message.should == "ANNOUNCE rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 2345\r\n\Date: \r\nSession: 123456789\r\nContent-Type: application/sdp\r\nContent-Length: 29\r\n\r\nv=1\r\no=bobo     \r\ns=\r\nt= \r\n\r\n"
    end
  end

  context "should build a SETUP message" do
    it "with default sequence, transport, client_port, and routing values" do
      message = RTSP::RequestMessages.setup @stream
      message.should == "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Transport: RTP/AVP;unicast;client_port=9000-9001\r\n\r\n"
    end

    it "with default sequence, transport, and client_port values" do
      message = RTSP::RequestMessages.setup(@stream, :routing => 'multicast')
      message.should == "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Transport: RTP/AVP;multicast;client_port=9000-9001\r\n\r\n"
    end

    it "with default sequence and transport values" do
      message = RTSP::RequestMessages.setup @stream, {
          :routing => 'multicast',
          :client_port => 8000
      }
      message.should == "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Transport: RTP/AVP;multicast;client_port=8000-8001\r\n\r\n"
    end

    it "with default sequence value" do
      message = RTSP::RequestMessages.setup @stream, {
        :routing => 'multicast',
        :client_port => 8000,
        :transport_spec => 'RTP/AVP/UDP'
      }
      message.should == "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Transport: RTP/AVP/UDP;multicast;client_port=8000-8001\r\n\r\n"
    end

    it "with default sequence value and passed in server_port value" do
      message = RTSP::RequestMessages.setup @stream, {
        :routing => 'multicast',
        :client_port => 8000,
        :transport_spec => 'RTP/AVP/UDP',
        :server_port => 6000
      }
      message.should == "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Transport: RTP/AVP/UDP;multicast;client_port=8000-8001;server_port=6000-6001\r\n\r\n"
    end

    it "with default transport, client_port, and routing values" do
      pending "Convert to use new style"
      message = RTSP::RequestMessages.setup(@stream, :sequence => 2345)
      message.should include "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 2345\r\n"
      message.should include "Transport: RTP/AVP;unicast;client_port=9000-9001\r\n\r\n"
      message.should include "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 2345\r\n\Transport: RTP/AVP;unicast;client_port=9000-9001\r\n\r\n"
      message.should include "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 2345\r\n\Transport: RTP/AVP;unicast;client_port=9000-9001\r\n\r\n"
      message.should include "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 2345\r\n\Transport: RTP/AVP;unicast;client_port=9000-9001\r\n\r\n"
    end
  end

  context "should build a PLAY message" do
    it "with default sequence and range values" do
      message = RTSP::RequestMessages.play(@stream, { :session => 12345 })
      message.should include "PLAY rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 1\r\n"
      message.should include "Session: 12345\r\n"
      message.should include "Range: npt=0.000-\r\n"
      message.should include "\r\n\r\n"
    end

    it "with default sequence value" do
      message = RTSP::RequestMessages.play @stream, { :session => 12345,
        :range => { :npt => "0.000-1.234" }
      }
      message.should include "PLAY rtsp://1.2.3.4/stream1 RTSP/1.0\r\n"
      message.should include "CSeq: 1\r\n"
      message.should include "Session: 12345\r\n"
      message.should include "Range: npt=0.000-1.234\r\n"
      message.should include "\r\n\r\n"
    end
  end

  context "#headers_to_s turns a Hash into an String of header strings" do
    it "single header, non-hyphenated name, hash value" do
      header = { :range => { :npt => "0.000-" } }

      string = RTSP::RequestMessages.headers_to_s(header)
      string.is_a?(String).should be_true
      string.should include "Range: npt=0.000-"
    end

    it "single header, hyphenated, non-hash value" do
      header = { :if_modified_since => "Sat, 29 Oct 1994 19:43:31 GMT" }

      string = RTSP::RequestMessages.headers_to_s(header)
      string.is_a?(String).should be_true
      string.should include "If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT"
    end

    it "two headers, mixed hyphenated, array & hash values" do
      headers = {
        :cache_control => ["no-cache", { :max_age => 12345 }],
        :content_type => ['application/sdp', 'application/x-rtsp-mh']
      }

      string = RTSP::RequestMessages.headers_to_s(headers)
      string.is_a?(String).should be_true
      string.should include "Cache-Control: no-cache;max_age=12345"
      string.should include "Content-Type: application/sdp, application/x-rtsp-mh"
    end
  end
end