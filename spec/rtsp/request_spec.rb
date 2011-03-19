require File.dirname(__FILE__) + '/../spec_helper'
require 'rtsp/message'
require 'rtsp/request'

describe RTSP::Request do
  before do
    @stream = "rtsp://1.2.3.4/stream1"
    @mock_socket = double 'MockSocket'
  end

  def build_request_with headers
    message = RTSP::Message.new(:options, "http://localhost") do
      headers.each_pair { |h| header h.key, h.value }
    end
    RTSP::Request.new(message, :socket => @mock_socket)
  end

  context "#initialize" do
    pending
  end
end