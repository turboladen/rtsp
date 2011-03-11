require File.dirname(__FILE__) + '/../spec_helper'
require 'rtsp/request'
require 'sdp'

describe "RTSP::Request messages" do
  before do
    @stream = "rtsp://1.2.3.4/stream1"
    @mock_socket = double 'MockSocket'
  end

  context "builds an OPTIONS message" do
    it "with default sequence number" do
      request = RTSP::Request.new({ :method => :options,
          :resource_url => @stream,
          :socket => @mock_socket })
      request.message.should == "OPTIONS rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\nCSeq: 1\r\nUser-Agent: RubyGemRTSP/0.1.0\r\n\r\n"
    end

    it "with passed-in sequence number" do
      request = RTSP::Request.new({ :method => :options,
          :resource_url => @stream,
          :headers => { :cseq => 2345 },
          :socket => @mock_socket })
      request.message.should == "OPTIONS rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\nCSeq: 2345\r\nUser-Agent: RubyGemRTSP/0.1.0\r\n\r\n"
    end
  end

  context "builds a DESCRIBE message" do
    it "with default sequence and accept values" do
      request = RTSP::Request.new({ :method => :describe,
          :resource_url => @stream,
          :socket => @mock_socket })
      request.message.should match /^DESCRIBE rtsp:/
      request.message.should include "DESCRIBE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should include "Accept: application/sdp\r\n"
      request.message.should match /\r\n\r\n$/
    end

    it "with default sequence value" do
      request = RTSP::Request.new({ :method => :describe,
          :resource_url => @stream,
          :headers => { :accept => 'application/sdp, application/rtsl' },
          :socket => @mock_socket })
      request.message.should match /^DESCRIBE rtsp:/
      request.message.should include "DESCRIBE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should include "Accept: application/sdp, application/rtsl\r\n"
      request.message.should match /\r\n\r\n$/
    end

    it "with passed-in sequence and accept values" do
      request = RTSP::Request.new({ :method => :describe,
          :resource_url => @stream,
          :headers => {
              :accept => 'application/sdp, application/rtsl',
              :cseq => 2345
          },
          :socket => @mock_socket })
      request.message.should match /^DESCRIBE rtsp:/
      request.message.should include "DESCRIBE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 2345\r\n"
      request.message.should include "Accept: application/sdp, application/rtsl\r\n"
      request.message.should match /\r\n\r\n$/
    end
  end

  context "builds a ANNOUNCE message" do
    it "with default sequence, content type, but no body" do
      request = RTSP::Request.new({ :method => :announce,
          :resource_url => @stream,
          :headers => {
              :session => 123456789
          },
          :socket => @mock_socket })

      request.message.should match /^ANNOUNCE rtsp:/
      request.message.should include "ANNOUNCE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should include "Session: 123456789\r\n"
      request.message.should include "Content-Type: application/sdp\r\n"
      request.message.should match /\r\n\r\n$/
    end

    it "with passed-in session and content type but no body" do
      request = RTSP::Request.new({ :method => :announce,
          :resource_url => @stream,
          :headers => {
              :session => 123456789,
              :content_type => 'application/sdp, application/rtsl'
          },
          :socket => @mock_socket })

      request.message.should match /^ANNOUNCE rtsp:/
      request.message.should include "ANNOUNCE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should include "Session: 123456789\r\n"
      request.message.should include "Content-Type: application/sdp, application/rtsl\r\n"
      request.message.should match /\r\n\r\n$/
    end

    it "with passed-in sequence, session, content-type, but no body " do
      request = RTSP::Request.new({ :method => :announce,
          :resource_url => @stream,
          :headers => {
              :session => 123456789,
              :content_type => 'application/sdp, application/rtsl',
              :cseq => 2345
          },
          :socket => @mock_socket })

      request.message.should match /^ANNOUNCE rtsp:/
      request.message.should include "ANNOUNCE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 2345\r\n"
      request.message.should include "Session: 123456789\r\n"
      request.message.should include "Content-Type: application/sdp, application/rtsl\r\n"
      request.message.should match /\r\n\r\n$/
    end

    it "with passed-in sequence, session, content-type, and SDP body" do
      sdp = SDP::Description.new
      sdp.protocol_version = 1
      sdp.username = 'bobo'

      request = RTSP::Request.new({ :method => :announce,
          :resource_url => @stream,
          :headers => {
              :session => 123456789,
              :content_type => 'application/sdp',
              :cseq => 2345
          },
          :body => sdp.to_s,
          :socket => @mock_socket })

      request.message.should match /^ANNOUNCE rtsp/
      request.message.should include "ANNOUNCE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 2345\r\n"
      request.message.should include "Session: 123456789\r\n"
      request.message.should include "Content-Type: application/sdp\r\n"
      request.message.should include "Content-Length: 29\r\n"
      request.message.should match /\r\n\r\nv=1\r\no=bobo     \r\ns=\r\nt= \r\n\r\n$/
    end
  end

  context "builds a SETUP message" do
    it "with default sequence, transport, client_port, and routing values" do
      request = RTSP::Request.new({ :method => :setup,
          :resource_url => @stream,
          :socket => @mock_socket })

      request.message.should match /^SETUP rtsp/
      request.message.should include "SETUP rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should include "Transport: RTP/AVP;unicast;client_port=9000-9001\r\n"
      request.message.should match /\r\n\r\n$/
    end

    it "with default sequence, transport, and client_port values" do
      request = RTSP::Request.new({ :method => :setup,
          :resource_url => @stream,
          :headers => { :transport => ["RTP/AVP", "multicast", { :client_port => "9000-9001" }]},
          :socket => @mock_socket })

      request.message.should match /^SETUP rtsp/
      request.message.should include "SETUP rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should include "Transport: RTP/AVP;multicast;client_port=9000-9001\r\n"
      request.message.should match /\r\n\r\n$/
    end

    it "with default transport, client_port, and routing values" do
      request = RTSP::Request.new({ :method => :setup,
          :resource_url => @stream,
          :headers => {
              :transport => ["RTP/AVP", "multicast", { :client_port => "9000-9001" }],
              :cseq => 2345
          },
          :socket => @mock_socket })

      request.message.should match /^SETUP rtsp/
      request.message.should include "SETUP rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 2345\r\n"
      request.message.should include "Transport: RTP/AVP;multicast;client_port=9000-9001\r\n"
      request.message.should match /\r\n\r\n$/
    end
  end

  context "builds a PLAY message" do
    it "with default sequence and range values" do
      request = RTSP::Request.new({ :method => :play,
          :resource_url => @stream,
          :headers => { :session => 123456789 },
          :socket => @mock_socket })

      request.message.should match /^PLAY rtsp/
      request.message.should include "PLAY rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should include "Session: 123456789\r\n"
      request.message.should include "Range: npt=0.000-\r\n"
      request.message.should match /\r\n\r\n/
    end

    it "with default sequence value" do
      request = RTSP::Request.new({ :method => :play,
          :resource_url => @stream,
          :headers => { :session => 123456789, :range => { :npt => "0.000-1.234" } },
          :socket => @mock_socket })

      request.message.should match /^PLAY rtsp/
      request.message.should include "PLAY rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should include "Session: 123456789\r\n"
      request.message.should include "Range: npt=0.000-1.234\r\n"
      request.message.should match /\r\n\r\n/
    end
  end

  context "builds a PAUSE message" do
    it "with required Request values" do
      request = RTSP::Request.new({ :method => :pause,
          :resource_url => @stream,
          :socket => @mock_socket })

      request.message.should match /^PAUSE rtsp/
      request.message.should include "PAUSE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should match /\r\n\r\n/
    end

    it "with session and range headers" do
      request = RTSP::Request.new({ :method => :pause,
          :resource_url => @stream,
          :headers => { :session => 123456789, :range => { :npt => "0.000" } },
          :socket => @mock_socket })

      request.message.should match /^PAUSE rtsp/
      request.message.should include "PAUSE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should include "Session: 123456789\r\n"
      request.message.should include "Range: npt=0.000\r\n"
      request.message.should match /\r\n\r\n/
    end
  end

  context "builds a TEARDOWN message" do
    it "with required Request values" do
      request = RTSP::Request.new({ :method => :teardown,
          :resource_url => @stream,
          :socket => @mock_socket })

      request.message.should match /^TEARDOWN rtsp/
      request.message.should include "TEARDOWN rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should match /\r\n\r\n/
    end

    it "with session and range headers" do
      request = RTSP::Request.new({ :method => :teardown,
          :resource_url => @stream,
          :headers => { :session => 123456789 },
          :socket => @mock_socket })

      request.message.should match /^TEARDOWN rtsp/
      request.message.should include "TEARDOWN rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should include "Session: 123456789\r\n"
      request.message.should match /\r\n\r\n/
    end
  end

  context "builds a GET_PARAMETER message" do
    it "with required Request values" do
      request = RTSP::Request.new({ :method => :get_parameter,
          :resource_url => @stream,
          :socket => @mock_socket })

      request.message.should match /^GET_PARAMETER rtsp/
      request.message.should include "GET_PARAMETER rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should match /\r\n\r\n/
    end

    it "with cseq, content type, session headers, and text body" do
      body = "packets_received\r\njitter\r\n"

      request = RTSP::Request.new({ :method => :get_parameter,
          :resource_url => @stream,
          :headers => { :cseq => 431,
              :content_type => 'text/parameters',
              :session => 123456789 },
          :body => body,
          :socket => @mock_socket })

      request.message.should match /^GET_PARAMETER rtsp/
      request.message.should include "GET_PARAMETER rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 431\r\n"
      request.message.should include "Session: 123456789\r\n"
      request.message.should include "Content-Type: text/parameters\r\n"
      request.message.should include "Content-Length: #{body.length}\r\n"
      request.message.should include body
      request.message.should match /\r\n\r\n/
    end
  end

  context "builds a SET_PARAMETER message" do
    it "with required Request values" do
      request = RTSP::Request.new({ :method => :set_parameter,
          :resource_url => @stream,
          :socket => @mock_socket })

      request.message.should match /^SET_PARAMETER rtsp/
      request.message.should include "SET_PARAMETER rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should match /\r\n\r\n/
    end

    it "with cseq, content type, session headers, and text body" do
      body = "barparam: barstuff\r\n"

      request = RTSP::Request.new({ :method => :set_parameter,
          :resource_url => @stream,
          :headers => { :cseq => 431,
              :content_type => 'text/parameters',
              :session => 123456789 },
          :body => body,
          :socket => @mock_socket })

      request.message.should match /^SET_PARAMETER rtsp/
      request.message.should include "SET_PARAMETER rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 431\r\n"
      request.message.should include "Session: 123456789\r\n"
      request.message.should include "Content-Type: text/parameters\r\n"
      request.message.should include "Content-Length: #{body.length}\r\n"
      request.message.should include body
      request.message.should match /\r\n\r\n/
    end
  end

  context "builds a REDIRECT message" do
    it "with required Request values" do
      request = RTSP::Request.new({ :method => :redirect,
          :resource_url => @stream,
          :socket => @mock_socket })

      request.message.should match /^REDIRECT rtsp/
      request.message.should include "REDIRECT rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should match /\r\n\r\n/
    end

    it "with cseq, location, and range headers" do
      request = RTSP::Request.new({ :method => :redirect,
          :resource_url => @stream,
          :headers => { :cseq => 732,
              :location => "rtsp://bigserver.com:8001",
              :range => { :clock => "19960213T143205Z-" }
          },
          :socket => @mock_socket })

      request.message.should match /^REDIRECT rtsp/
      request.message.should include "REDIRECT rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 732\r\n"
      request.message.should include "Location: rtsp://bigserver.com:8001\r\n"
      request.message.should include "Range: clock=19960213T143205Z-\r\n"
      request.message.should match /\r\n\r\n/
    end
  end

  context "builds a RECORD message" do
    it "with required Request values" do
      request = RTSP::Request.new({ :method => :record,
          :resource_url => @stream,
          :socket => @mock_socket })

      request.message.should match /^RECORD rtsp/
      request.message.should include "RECORD rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 1\r\n"
      request.message.should match /\r\n\r\n/
    end

    it "with cseq, session, and conference headers" do
      request = RTSP::Request.new({ :method => :record,
          :resource_url => @stream,
          :headers => { :cseq => 954,
              :session => 12345678,
              :conference => "128.16.64.19/32492374"
          },
          :socket => @mock_socket })

      request.message.should match /^RECORD rtsp/
      request.message.should include "RECORD rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      request.message.should include "CSeq: 954\r\n"
      request.message.should include "Session: 12345678\r\n"
      request.message.should include "Conference: 128.16.64.19/32492374\r\n"
      request.message.should match /\r\n\r\n/
    end
  end
end
