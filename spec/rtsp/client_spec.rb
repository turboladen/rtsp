require File.dirname(__FILE__) + '/../spec_helper'
require 'rtsp/client'

describe RTSP::Client do
  describe "#initialize" do
    before :each do
      mock_socket = double 'MockSocket'
      @client = RTSP::Client.new "rtsp://localhost", :socket => mock_socket
    end

    it "sets @cseq to 1" do
      @client.instance_variable_get(:@cseq).should == 1
    end

    it "sets @session_state to :inactive" do
      @client.instance_variable_get(:@session_state).should == :inactive
    end

    it "sets @server_uri to be a URI containing the first init param + 554" do
      @client.instance_variable_get(:@server_uri).should be_a(URI)
      @client.instance_variable_get(:@server_uri).to_s.should ==
          "rtsp://localhost:554"
    end
  end
  it "increments the sequence number after receiving an OK response" do

  end

  describe "#configure" do
    before :each do
      mock_socket = double 'MockSocket'
      @client = RTSP::Client.new "rtsp://localhost", :socket => mock_socket
    end

    describe "log" do
      it "should default to true" do
        @client.log?.should be_true
      end

      it "should set whether to log RTSP requests/responses" do
        @client.configure { |config| config.log = false }
        @client.log?.should be_false
      end
    end

    describe "logger" do
      it "should set the logger to use" do
        MyLogger = Class.new
        @client.configure { |config| config.logger = MyLogger }
        @client.logger.should == MyLogger
      end

      it "should default to Logger writing to STDOUT" do
        @client.logger.should be_a(Logger)
      end
    end

    describe "log_level" do
      it "should default to :debug" do
        @client.log_level.should == :debug
      end

      it "should set the log level to use" do
        @client.configure { |config| config.log_level = :info }
        @client.log_level.should == :info
      end
    end
  end

  context "#server_url" do
    before :each do
      mock_socket = double 'MockSocket'
      @client = RTSP::Client.new "rtsp://localhost", :socket => mock_socket
    end

    it "allows for changing the server URL on the fly" do
      @client.server_uri.to_s.should == "rtsp://localhost:554"
      @client.server_url = "rtsp://localhost:8080"
      @client.server_uri.to_s.should == "rtsp://localhost:8080"
    end

    it "raises when passing in something other than a String" do
      @client.server_uri.to_s.should == "rtsp://localhost:554"
      lambda { @client.server_url = [] }.should raise_error
    end
  end
end