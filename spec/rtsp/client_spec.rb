require File.dirname(__FILE__) + '/../spec_helper'
require 'rtsp/client'

describe RTSP::Client do

  it "increments the sequence number after receiving an OK response" do

  end

  context "#server_url" do
    before :each do
      @client = RTSP::Client.new "rtsp://localhost"
    end

    it "allows for changing the server URL on the fly" do
      @client.server_uri.to_s.should == "rtsp://localhost"
      @client.server_url = "rtsp://localhost:8080"
      @client.server_uri.to_s.should == "rtsp://localhost:8080"
    end

    it "raises when passing in something other than a String" do
      @client.server_uri.to_s.should == "rtsp://localhost"
      lambda { @client.server_url = [] }.should raise_error
    end
  end
end