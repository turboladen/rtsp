require File.dirname(__FILE__) + '/../spec_helper'
require 'rtsp/request_messages'

describe RTSP::RequestMessages do
  include RTSP::RequestMessages

  it "should build an OPTIONS message" do
    stream = "rtsp://1.2.3.4/stream1"
    message = RTSP::RequestMessages.options stream
    message.should == "OPTIONS rtsp://1.2.3.4/stream1 RTSP/1.0\r\nCSeq: 1\r\n\r\n"
  end
end