require File.dirname(__FILE__) + '/../spec_helper'
require 'rtsp/request_messages'

describe RTSP::RequestMessages do
  include RTSP::RequestMessages

  before do
    @stream = "rtsp://1.2.3.4/stream1"
    @options = {}
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
    it "with default sequence and accept value" do
      message = RTSP::RequestMessages.describe @stream
      message.should == "DESCRIBE rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Accept: application/sdp\r\n\r\n"
    end

    it "with default sequence value" do
      @options[:accept] = ['application/sdp', 'application/rtsl']
      message = RTSP::RequestMessages.describe(@stream, @options)
      message.should == "DESCRIBE rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\Accept: application/sdp, application/rtsl\r\n\r\n"
    end
  end
end