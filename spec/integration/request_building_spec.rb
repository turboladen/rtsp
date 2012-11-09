require 'spec_helper'
require 'rtsp/request'

describe "Request building" do
  describe "OPTIONS" do
    let(:stream) { "rtsp://1.2.3.4/stream1" }

    context "with default sequence number" do
      it "builds the request" do
        message = RTSP::Request.options(stream)
        message.to_s.should == "OPTIONS rtsp://1.2.3.4:554/stream1 RTSP/1.0\r\nCSeq: 1\r\nUser-Agent: RubyRTSP/#{RTSP::VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})\r\n\r\n"
      end
    end
  end
end
