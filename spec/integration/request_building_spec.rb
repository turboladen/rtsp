require 'spec_helper'
require 'rtsp/request'

describe "Request building" do
  let(:stream) { "rtsp://1.2.3.4/stream1" }

  describe "an OPTIONS request string" do
    context "with default sequence number" do
      it "builds the request" do
        request = RTSP::Request.options(stream)
        request.to_s.should == %Q{OPTIONS rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
\r
}
      end
    end

    context "with new sequence number" do
      it "builds the request" do
        request = RTSP::Request.options(stream)
        request.header :cseq, 2345
        request.to_s.should == %Q{OPTIONS rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 2345\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
\r
}
      end
    end
  end

  describe "a DESCRIBE request string" do
    context "with default sequence and accept values" do
      it "builds the request" do
        request = RTSP::Request.describe(stream).to_s

        request.should == %Q{DESCRIBE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Accept: application/sdp\r
\r
}
      end
    end

    context "with non-default Accept" do
      it "builds the request" do
        request = RTSP::Request.describe(stream).with_headers({
          accept: 'application/sdp, application/rtsl' }).to_s

        request.should == %Q{DESCRIBE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Accept: application/sdp, application/rtsl\r
\r
}
      end
    end

    context "with non-default Sequence and Accept values" do
      it "builds the request" do
        request = RTSP::Request.describe(stream).with_headers({
          accept: 'application/sdp, application/rtsl',
          cseq: 2345 }).to_s

        request.should == %Q{DESCRIBE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 2345\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Accept: application/sdp, application/rtsl\r
\r
}
      end
    end
  end

  describe "an ANNOUNCE request string" do
    context "with default sequence, content type, but no body" do
      it "builds the request" do
        request = RTSP::Request.announce(stream).
          with_headers({ session: 123456789 }).to_s

        request.should == %Q{ANNOUNCE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Session: 123456789\r
Content-Type: application/sdp\r
\r
}
      end
    end

    context "with passed-in session and content type but no body" do
      it "builds the request" do
        request = RTSP::Request.announce(stream).with_headers({
          session: 123456789,
          content_type: 'application/sdp, application/rtsl' }).to_s

        request.should == %Q{ANNOUNCE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Session: 123456789\r
Content-Type: application/sdp, application/rtsl\r
\r
}
      end
    end

    context "with passed-in sequence, session, content-type, but no body " do
      it "builds the request" do
        request = RTSP::Request.announce(stream).with_headers({
          session: 123456789,
          content_type: 'application/sdp, application/rtsl',
          cseq: 2345 }).to_s

        request.should == %Q{ANNOUNCE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 2345\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Session: 123456789\r
Content-Type: application/sdp, application/rtsl\r
\r
}
      end
    end

    context "with passed-in sequence, session, content-type, and SDP body" do
      it "builds the request" do
        sdp_string = "this is a fake description"
        sdp = double "SDP::Description"
        sdp.stub(:to_s).and_return sdp_string

        request = RTSP::Request.announce(stream).with_headers_and_body({
          session: 123456789,
          content_type: 'application/sdp',
          cseq: 2345,
          body: sdp.to_s
        }).to_s

        request.should == %Q{ANNOUNCE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 2345\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Session: 123456789\r
Content-Type: application/sdp\r
Content-Length: #{sdp_string.length}\r
\r
#{sdp_string}}
      end
    end
  end

  describe "a SETUP string" do
    context "with default sequence, client_port, and routing values" do
      it "builds the request" do
        request = RTSP::Request.setup(stream).to_s

        request.should == %Q{SETUP rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
\r
}
      end
    end

    context "with default sequence, transport, and client_port values" do
      it "builds the request" do
        request = RTSP::Request.setup(stream).
          with_headers({
            transport: {
              streaming_protocol: "RTP",
              profile: "AVP",
              broadcast_type: "multicast",
              client_port: {
                rtp: 9000,
                rtcp: 9001
              }
            }
          }).to_s

        request.should == %Q{SETUP rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Transport: RTP/AVP;multicast;client_port=9000-9001\r
\r
}
      end
    end

    context "with default transport, client_port, and routing values" do
      it "builds the request" do
        request = RTSP::Request.setup(stream).with_headers({
          transport: {
            streaming_protocol: "RTP",
            profile: "AVP",
            broadcast_type: "multicast",
            client_port: { rtp: 9000, rtcp: 9001 }
          }, cseq: 2345 }).to_s

        request.should == %Q{SETUP rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 2345\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Transport: RTP/AVP;multicast;client_port=9000-9001\r
\r
}
      end
    end
  end

  describe "a PLAY string" do
    context "with default sequence and range values" do
      it "builds the request" do
        request = RTSP::Request.play(stream).with_headers({
          session: 123456789 }).to_s

        request.should == %Q{PLAY rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Session: 123456789\r
Range: npt=0.000-\r
\r
}
      end
    end

    context "with default sequence value" do
      it "builds the request" do
        request = RTSP::Request.play(stream).with_headers({
          session: 123456789,
          range: { :npt => "0.000-1.234" } }).to_s

        request.should == %Q{PLAY rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Session: 123456789\r
Range: npt=0.000-1.234\r
\r
}
      end
    end
  end

  describe "a PAUSE string" do
    context "with required Request values" do
      it "builds the request" do
        request = RTSP::Request.pause(stream).to_s

        request.should == %Q{PAUSE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
\r
}
      end
    end

    context "with session and range headers" do
      it "builds the request" do
        request = RTSP::Request.pause(stream).with_headers({
          session: 123456789,
          range: { :npt => "0.000" } }).to_s

        request.should == %Q{PAUSE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Session: 123456789\r
Range: npt=0.000\r
\r
}
      end
    end
  end

  context "a TEARDOWN string" do
    context "with required Request values" do
      it "builds the request" do
        request = RTSP::Request.teardown(stream).to_s

        request.should == %Q{TEARDOWN rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
\r
}
      end
    end

    context "with session and range headers" do
      it "builds the request" do
        request = RTSP::Request.teardown(stream).with_headers({
          session: 123456789 }).to_s

        request.should == %Q{TEARDOWN rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Session: 123456789\r
\r
}
      end
    end
  end

  describe "a GET_PARAMETER string" do
    context "with required Request values" do
      it "builds the request" do
        request = RTSP::Request.get_parameter(stream).to_s

        request.should == %Q{GET_PARAMETER rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Content-Type: text/parameters\r
\r
}
      end
    end

    context "with cseq, content type, session headers, and text body" do
      it "builds the request" do
        the_body = "packets_received\r\njitter\r\n"

        request = RTSP::Request.get_parameter(stream).with_headers_and_body({
          cseq: 431,
          content_type: 'text/parameters',
          session: 123456789,
          body: the_body
        }).to_s

        request.should == %Q{GET_PARAMETER rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 431\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Session: 123456789\r
Content-Type: text/parameters\r
Content-Length: #{the_body.length}\r
\r
#{the_body}}
      end
    end
  end

  describe "a SET_PARAMETER string" do
    context "with required Request values" do
      it "builds the request" do
        request = RTSP::Request.set_parameter(stream).to_s

        request.should == %Q{SET_PARAMETER rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Content-Type: text/parameters\r
\r
}
      end
    end

    context "with cseq, content type, session headers, and text body" do
      it "builds the request" do
        the_body = "barparam: barstuff\r\n"

        request = RTSP::Request.set_parameter(stream).with_headers_and_body({
          cseq: 431,
          content_type: 'text/parameters',
          session: 123456789,
          body: the_body
        }).to_s

        request.should == %Q{SET_PARAMETER rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 431\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Session: 123456789\r
Content-Type: text/parameters\r
Content-Length: #{the_body.length}\r
\r
#{the_body}}
      end
    end
  end

  describe "a REDIRECT string" do
    context "with required Request values" do
      it "builds the request" do
        request = RTSP::Request.redirect(stream).to_s

        request.should == %Q{REDIRECT rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
\r
}
      end
    end

    context "with cseq, location, and range headers" do
      it "builds the request" do
        request = RTSP::Request.redirect(stream).with_headers({
          cseq: 732,
          location: "rtsp://bigserver.com:8001",
          range: { :clock => "19960213T143205Z-" } }).to_s

        request.should == %Q{REDIRECT rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 732\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Location: rtsp://bigserver.com:8001\r
Range: clock=19960213T143205Z-\r
\r
}
      end
    end
  end

  describe "a RECORD string" do
    context "with required Request values" do
      it "builds the request" do
        request = RTSP::Request.record(stream).to_s

        request.should == %Q{RECORD rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 1\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
\r
}
      end
    end

    context "with cseq, session, and conference headers" do
      it "builds the request" do
        request = RTSP::Request.record(stream).with_headers({
          cseq: 954,
          session: 12345678,
          conference: "128.16.64.19/32492374" }).to_s

        request.should == %Q{RECORD rtsp://1.2.3.4:554/stream1 RTSP/1.0\r
CSeq: 954\r
User-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r
Session: 12345678\r
Conference: 128.16.64.19/32492374\r
\r
}
      end
    end
  end

end
