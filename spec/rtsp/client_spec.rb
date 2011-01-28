require File.dirname(__FILE__) + '/../spec_helper'
require 'rtsp/client'

describe RTSP::Client do
  context "parses the URI on init" do
    it "with scheme, IP, port, and path" do
      @rtsp_client = RTSP::Client.new "rtsp://64.202.98.91:554/sa.sdp"
      @rtsp_client.server_uri.scheme.should == "rtsp"
      @rtsp_client.server_uri.host.should == "64.202.98.91"
      @rtsp_client.server_uri.port.should == 554
      @rtsp_client.server_uri.path.should == "/sa.sdp"
    end

    it "with scheme, IP, path; port defaults to 554" do
      @rtsp_client = RTSP::Client.new "rtsp://64.202.98.91/sa.sdp"
      @rtsp_client.server_uri.scheme.should == "rtsp"
      @rtsp_client.server_uri.host.should == "64.202.98.91"
      @rtsp_client.server_uri.port.should == 554
      @rtsp_client.server_uri.path.should == "/sa.sdp"
    end

    it "with IP, path; port defaults to 554; scheme defaults to 'rtsp'" do
      @rtsp_client = RTSP::Client.new "64.202.98.91/sa.sdp"
      @rtsp_client.server_uri.scheme.should == "rtsp"
      @rtsp_client.server_uri.host.should == "64.202.98.91"
      @rtsp_client.server_uri.port.should == 554
      @rtsp_client.server_uri.path.should == "/sa.sdp"
    end

    it "with scheme, IP, port" do
      @rtsp_client = RTSP::Client.new "rtsp://64.202.98.91:554"
      @rtsp_client.server_uri.scheme.should == "rtsp"
      @rtsp_client.server_uri.host.should == "64.202.98.91"
      @rtsp_client.server_uri.port.should == 554
      @rtsp_client.server_uri.path.should == ""
    end
  end
end