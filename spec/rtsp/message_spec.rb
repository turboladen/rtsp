require 'sdp'
require_relative '../spec_helper'
require 'rtsp/message'

describe "RTSP::Message" do
  before do
    @stream = "rtsp://1.2.3.4/stream1"
  end

  it "raises if the header type isn't a Symbol" do
    message = RTSP::Message.options(@stream)
    lambda { message.header "hi", "everyone"
      }.should raise_error RTSP::Exception
  end

  context "builds an OPTIONS string" do
    it "with default sequence number" do
      message = RTSP::Message.options(@stream)
      message.to_s.should == "OPTIONS rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\nCSeq: 1\r\nUser-Agent: RubyRTSP/0.1.0 (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r\n\r\n"
    end

    it "with new sequence number" do
      message = RTSP::Message.options(@stream)
      message.header :cseq, 2345
      message.to_s.should == "OPTIONS rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\nCSeq: 2345\r\nUser-Agent: RubyRTSP/0.1.0 (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r\n\r\n"
    end
  end

  context "builds a DESCRIBE string" do
    it "with default sequence and accept values" do
      message = RTSP::Message.describe(@stream)
      message.to_s.should match /^DESCRIBE rtsp:/
      message.to_s.should include "DESCRIBE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should include "Accept: application/sdp\r\n"
      message.to_s.should match /\r\n\r\n$/
    end

    it "with default sequence value" do
      message = RTSP::Message.describe(@stream).with_headers({
        accept: 'application/sdp, application/rtsl' })
      message.to_s.should match /^DESCRIBE rtsp:/
      message.to_s.should include "DESCRIBE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should include "Accept: application/sdp, application/rtsl\r\n"
      message.to_s.should match /\r\n\r\n$/
    end

    it "with new sequence and accept values" do
      message = RTSP::Message.describe(@stream).with_headers({
        accept: 'application/sdp, application/rtsl',
        cseq:  2345 })

      message.to_s.should match /^DESCRIBE rtsp:/
      message.to_s.should include "DESCRIBE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 2345\r\n"
      message.to_s.should include "Accept: application/sdp, application/rtsl\r\n"
      message.to_s.should match /\r\n\r\n$/
    end
  end

  context "builds a ANNOUNCE string" do
    it "with default sequence, content type, but no body" do
      message = RTSP::Message.announce(@stream).with_headers({ session: 123456789 })

      message.to_s.should match /^ANNOUNCE rtsp:/
      message.to_s.should include "ANNOUNCE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should include "Session: 123456789\r\n"
      message.to_s.should include "Content-Type: application/sdp\r\n"
      message.to_s.should match /\r\n\r\n$/
    end

    it "with passed-in session and content type but no body" do
      message = RTSP::Message.announce(@stream).with_headers({
        session: 123456789,
        content_type: 'application/sdp, application/rtsl'})

      message.to_s.should match /^ANNOUNCE rtsp:/
      message.to_s.should include "ANNOUNCE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should include "Session: 123456789\r\n"
      message.to_s.should include "Content-Type: application/sdp, application/rtsl\r\n"
      message.to_s.should match /\r\n\r\n$/
    end

    it "with passed-in sequence, session, content-type, but no body " do
      message = RTSP::Message.announce(@stream).with_headers({
        session: 123456789,
        content_type: 'application/sdp, application/rtsl',
        cseq: 2345})

      message.to_s.should match /^ANNOUNCE rtsp:/
      message.to_s.should include "ANNOUNCE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 2345\r\n"
      message.to_s.should include "Session: 123456789\r\n"
      message.to_s.should include "Content-Type: application/sdp, application/rtsl\r\n"
      message.to_s.should match /\r\n\r\n$/
    end

    it "with passed-in sequence, session, content-type, and SDP body" do
      sdp = SDP::Description.new
      sdp.protocol_version = 1
      sdp.username = 'bobo'

      message = RTSP::Message.announce(@stream).with_headers({
        session: 123456789,
        content_type: 'application/sdp',
        cseq: 2345 })
      message.body = sdp.to_s

      message.to_s.should match /^ANNOUNCE rtsp/
      message.to_s.should include "ANNOUNCE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 2345\r\n"
      message.to_s.should include "Session: 123456789\r\n"
      message.to_s.should include "Content-Type: application/sdp\r\n"
      message.to_s.should include "Content-Length: 29\r\n"
      message.to_s.should match /\r\n\r\nv=1\r\no=bobo     \r\ns=\r\nt= \r\n\r\n$/
    end
  end

  context "builds a SETUP string" do
    it "with default sequence, transport, client_port, and routing values" do
      message = RTSP::Message.setup(@stream)

      message.to_s.should match /^SETUP rtsp/
      message.to_s.should include "SETUP rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should include "Transport: RTP/AVP;unicast;client_port=9000-9001\r\n"
      message.to_s.should match /\r\n\r\n$/
    end

    it "with default sequence, transport, and client_port values" do
      message = RTSP::Message.setup(@stream).with_headers({
        transport: ["RTP/AVP", "multicast", { :client_port => "9000-9001" }] })

      message.to_s.should match /^SETUP rtsp/
      message.to_s.should include "SETUP rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should include "Transport: RTP/AVP;multicast;client_port=9000-9001\r\n"
      message.to_s.should match /\r\n\r\n$/
    end

    it "with default transport, client_port, and routing values" do
      message = RTSP::Message.setup(@stream).with_headers({
        transport: ["RTP/AVP", "multicast", { :client_port => "9000-9001" }],
        cseq: 2345 })

      message.to_s.should match /^SETUP rtsp/
      message.to_s.should include "SETUP rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 2345\r\n"
      message.to_s.should include "Transport: RTP/AVP;multicast;client_port=9000-9001\r\n"
      message.to_s.should match /\r\n\r\n$/
    end
  end

  context "builds a PLAY string" do
    it "with default sequence and range values" do
      message = RTSP::Message.play(@stream).with_headers({
        session: 123456789 })

      message.to_s.should match /^PLAY rtsp/
      message.to_s.should include "PLAY rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should include "Session: 123456789\r\n"
      message.to_s.should include "Range: npt=0.000-\r\n"
      message.to_s.should match /\r\n\r\n/
    end

    it "with default sequence value" do
      message = RTSP::Message.play(@stream).with_headers({
        session: 123456789,
        range: { :npt => "0.000-1.234" } })

      message.to_s.should match /^PLAY rtsp/
      message.to_s.should include "PLAY rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should include "Session: 123456789\r\n"
      message.to_s.should include "Range: npt=0.000-1.234\r\n"
      message.to_s.should match /\r\n\r\n/
    end
  end

  context "builds a PAUSE string" do
    it "with required Request values" do
      message = RTSP::Message.pause(@stream)

      message.to_s.should match /^PAUSE rtsp/
      message.to_s.should include "PAUSE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should match /\r\n\r\n/
    end

    it "with session and range headers" do
      message = RTSP::Message.pause(@stream).with_headers({
        session: 123456789,
        range: { :npt => "0.000" } })

      message.to_s.should match /^PAUSE rtsp/
      message.to_s.should include "PAUSE rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should include "Session: 123456789\r\n"
      message.to_s.should include "Range: npt=0.000\r\n"
      message.to_s.should match /\r\n\r\n/
    end
  end

  context "builds a TEARDOWN string" do
    it "with required Request values" do
      message = RTSP::Message.teardown(@stream)

      message.to_s.should match /^TEARDOWN rtsp/
      message.to_s.should include "TEARDOWN rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should match /\r\n\r\n/
    end

    it "with session and range headers" do
      message = RTSP::Message.teardown(@stream).with_headers({
        session: 123456789 })

      message.to_s.should match /^TEARDOWN rtsp/
      message.to_s.should include "TEARDOWN rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should include "Session: 123456789\r\n"
      message.to_s.should match /\r\n\r\n/
    end
  end

  context "builds a GET_PARAMETER string" do
    it "with required Request values" do
      message = RTSP::Message.get_parameter(@stream)

      message.to_s.should match /^GET_PARAMETER rtsp/
      message.to_s.should include "GET_PARAMETER rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should match /\r\n\r\n/
    end

    it "with cseq, content type, session headers, and text body" do
      the_body = "packets_received\r\njitter\r\n"

      message = RTSP::Message.get_parameter(@stream).with_headers({
        cseq: 431,
        content_type: 'text/parameters',
        session: 123456789 })

      message.body = the_body

      message.to_s.should match /^GET_PARAMETER rtsp/
      message.to_s.should include "GET_PARAMETER rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 431\r\n"
      message.to_s.should include "Session: 123456789\r\n"
      message.to_s.should include "Content-Type: text/parameters\r\n"
      message.to_s.should include "Content-Length: #{the_body.length}\r\n"
      message.to_s.should include the_body
      message.to_s.should match /\r\n\r\n/
    end
  end

  context "builds a SET_PARAMETER string" do
    it "with required Request values" do
      message = RTSP::Message.set_parameter(@stream)

      message.to_s.should match /^SET_PARAMETER rtsp/
      message.to_s.should include "SET_PARAMETER rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should match /\r\n\r\n/
    end

    it "with cseq, content type, session headers, and text body" do
      the_body = "barparam: barstuff\r\n"

      message = RTSP::Message.set_parameter(@stream).with_headers({
        cseq: 431,
        content_type: 'text/parameters',
        session: 123456789 })
      message.body = the_body

      message.to_s.should match /^SET_PARAMETER rtsp/
      message.to_s.should include "SET_PARAMETER rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 431\r\n"
      message.to_s.should include "Session: 123456789\r\n"
      message.to_s.should include "Content-Type: text/parameters\r\n"
      message.to_s.should include "Content-Length: #{the_body.length}\r\n"
      message.to_s.should include the_body
      message.to_s.should match /\r\n\r\n/
    end
  end

  context "builds a REDIRECT string" do
    it "with required Request values" do
      message = RTSP::Message.redirect(@stream)

      message.to_s.should match /^REDIRECT rtsp/
      message.to_s.should include "REDIRECT rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should match /\r\n\r\n/
    end

    it "with cseq, location, and range headers" do
      message = RTSP::Message.redirect(@stream).with_headers({
        cseq: 732,
        location: "rtsp://bigserver.com:8001",
        range: { :clock => "19960213T143205Z-" } })

      message.to_s.should match /^REDIRECT rtsp/
      message.to_s.should include "REDIRECT rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 732\r\n"
      message.to_s.should include "Location: rtsp://bigserver.com:8001\r\n"
      message.to_s.should include "Range: clock=19960213T143205Z-\r\n"
      message.to_s.should match /\r\n\r\n/
    end
  end

  context "builds a RECORD string" do
    it "with required Request values" do
      message = RTSP::Message.record(@stream)

      message.to_s.should match /^RECORD rtsp/
      message.to_s.should include "RECORD rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 1\r\n"
      message.to_s.should match /\r\n\r\n/
    end

    it "with cseq, session, and conference headers" do
      message = RTSP::Message.record(@stream).with_headers({
        cseq: 954,
        session: 12345678,
        conference: "128.16.64.19/32492374" })

      message.to_s.should match /^RECORD rtsp/
      message.to_s.should include "RECORD rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\n"
      message.to_s.should include "CSeq: 954\r\n"
      message.to_s.should include "Session: 12345678\r\n"
      message.to_s.should include "Conference: 128.16.64.19/32492374\r\n"
      message.to_s.should match /\r\n\r\n/
    end
  end

  context "#to_s turns a Hash into an String of header strings" do
    it "single header, non-hyphenated name, hash value" do
      message = RTSP::Message.play(@stream).with_headers({
          range: { npt: "0.000-" }
      })

      string = message.to_s
      string.is_a?(String).should be_true
      string.should include "Range: npt=0.000-"
    end

    it "single header, hyphenated, non-hash value" do
      message = RTSP::Message.play(@stream).with_headers({
          :if_modified_since => "Sat, 29 Oct 1994 19:43:31 GMT"
      })

      string = message.to_s
      string.is_a?(String).should be_true
      string.should include "If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT"
    end

    it "two headers, mixed hyphenated, array & hash values" do
      message = RTSP::Message.redirect(@stream).with_headers({
          :cache_control => ["no-cache", { :max_age => 12345 }],
          :content_type => ['application/sdp', 'application/x-rtsp-mh']
      })

      string = message.to_s
      string.is_a?(String).should be_true
      string.should include "Cache-Control: no-cache;max_age=12345"
      string.should include "Content-Type: application/sdp, application/x-rtsp-mh"
    end
  end

  describe "#with_headers" do
    it "returns an RTSP::Message" do
      message = RTSP::Message.options(@stream)
      result = message.with_headers({ test: "test" })
      result.class.should == RTSP::Message
    end
  end

  describe "#with_body" do
    it "adds the passed-in text to the body of the message" do
      new_body = "1234567890"
      message = RTSP::Message.record("rtsp://localhost/track").with_body(new_body)
      message.to_s.should match /\r\n\r\n#{new_body}$/
    end

    it "adds the Content-Length header to reflect the body" do
      new_body = "1234567890"
      message = RTSP::Message.record("rtsp://localhost/track").with_body(new_body)
      message.to_s.should match /Content-Length: #{new_body.size}\r\n/
    end
  end

  describe "#respond_to?" do
    it "returns true to each method in the list of supported method types" do
      RTSP::Message.instance_variable_get(:@message_types).each do |m|
        RTSP::Message.respond_to?(m).should be_true
      end
    end

    it "returns false to a method that's not in the list of supported methods" do
      RTSP::Message.respond_to?(:meow).should be_false
    end
  end

  describe "#method_missing" do
    it "returns " do
      lambda { RTSP::Message.meow }.should raise_error NoMethodError
    end
  end
end
