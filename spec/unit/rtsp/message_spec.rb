require 'sdp'
require 'spec_helper'
require 'rtsp/message'


describe RTSP::Message do
  let(:stream) { "rtsp://1.2.3.4/stream1" }

  describe "#header" do
    it "raises if the header type isn't a Symbol" do
      message = RTSP::Message.new

      expect {
        message.header "hi", "everyone"
      }.to raise_error RTSP::Error
    end
  end



  context "#to_s turns a Hash into an String of header strings" do
    it "single header, non-hyphenated name, hash value" do
      message = RTSP::Message.play(stream).with_headers({
        range: { npt: "0.000-" }
      })

      string = message.to_s
      string.is_a?(String).should be_true
      string.should include "Range: npt=0.000-"
    end

    it "single header, hyphenated, non-hash value" do
      message = RTSP::Message.play(stream).with_headers({
        :if_modified_since => "Sat, 29 Oct 1994 19:43:31 GMT"
      })

      string = message.to_s
      string.is_a?(String).should be_true
      string.should include "If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT"
    end

    it "two headers, mixed hyphenated, array & hash values" do
      message = RTSP::Message.redirect(stream).with_headers({
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
      message = RTSP::Message.options(stream)
      result = message.with_headers({ test: "test" })
      result.class.should == RTSP::Message
    end
  end

  describe "#with_body" do
    it "adds the passed-in text to the body of the message" do
      new_body = "1234567890"
      message = RTSP::Message.record("rtsp://localhost/track").with_body(new_body)
      message.to_s.should match(/\r\n\r\n#{new_body}$/)
    end

    it "adds the Content-Length header to reflect the body" do
      new_body = "1234567890"
      message = RTSP::Message.record("rtsp://localhost/track").with_body(new_body)
      message.to_s.should match(/Content-Length: #{new_body.size}\r\n/)
    end
  end

  describe "#respond_to?" do
    it "returns true to each method in the list of supported method types" do
      RTSP::Message.instance_variable_get(:@method_types).each do |m|
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
