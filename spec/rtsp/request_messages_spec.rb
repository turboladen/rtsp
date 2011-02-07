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
      message = RTSP::RequestMessages.setup(@stream, :sequence => 2345)
      message.should == "SETUP rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 2345\r\n\Transport: RTP/AVP;unicast;client_port=9000-9001\r\n\r\n"
    end
  end

  context "should build a PLAY message" do
    it "with default sequence, session, and range values" do
      message = RTSP::RequestMessages.play(@stream)
      message.should == "PLAY rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Session: 12345\r\nRange: npt=0.000-\r\n\r\n"
    end

    it "with default sequence and session values" do
      message = RTSP::RequestMessages.play @stream, :range => { :npt => "0.000-1.234" }
      message.should == "PLAY rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Session: 12345\r\nRange: npt=0.000-1.234\r\n\r\n"
    end
  end

  it "turns a Hash of headers in to strings" do
    header = { :range => { :npt => "0.000-" } }
    RTSP::RequestMessages.module_eval do
      module_function(:stringify_headers)
      public(:stringify_headers)
    end
    strings = RTSP::RequestMessages.stringify_headers(header)
    strings.first.should == "Range: npt=0.000-"
  end
end