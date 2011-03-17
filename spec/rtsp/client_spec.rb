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

    it "sets @session_state to :init" do
      @client.instance_variable_get(:@session_state).should == :init
    end

    it "sets @server_uri to be a URI containing the first init param + 554" do
      @client.instance_variable_get(:@server_uri).should be_a(URI)
      @client.instance_variable_get(:@server_uri).to_s.should ==
          "rtsp://localhost:554"
    end
  end

  describe ".configure" do
    around do |example|
      RTSP::Client.reset_config!
      example.run
      RTSP::Client.reset_config!
      RTSP::Client.log = false
    end

    before :each do
      mock_socket = double 'MockSocket'
      @client = RTSP::Client.new "rtsp://localhost", :socket => mock_socket
    end

    describe "log" do
      it "should default to true" do
        RTSP::Client.log?.should be_true
      end

      it "should set whether to log RTSP requests/responses" do
        RTSP::Client.configure { |config| config.log = false }
        RTSP::Client.log?.should be_false
      end
    end

    describe "logger" do
      it "should set the logger to use" do
        MyLogger = Class.new
        RTSP::Client.configure { |config| config.logger = MyLogger }
        RTSP::Client.logger.should == MyLogger
      end

      it "should default to Logger writing to STDOUT" do
        RTSP::Client.logger.should be_a(Logger)
      end
    end

    describe "log_level" do
      it "should default to :debug" do
        RTSP::Client.log_level.should == :debug
      end

      it "should set the log level to use" do
        RTSP::Client.configure { |config| config.log_level = :info }
        RTSP::Client.log_level.should == :info
      end
    end
  end

  it "handles empty non-existent CSeq header" do
    pending
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

  describe "#options" do
    before :each do
      mock_socket = double 'MockSocket', :send => "", :recvfrom => [OPTIONS_RESPONSE]
      mock_logger = double 'MockLogger', :send => nil
      @client = RTSP::Client.new "rtsp://localhost", :socket => mock_socket
      RTSP::Client.reset_config!
      RTSP::Client.configure { |config| config.log = false }
      @client.logger = mock_logger
    end

    it "extracts the server's supported methods" do
      @client.options
      @client.instance_variable_get(:@supported_methods).should ==
          [:options, :describe, :setup, :teardown, :play, :pause]
    end

    it "returns a Response" do
      response = @client.options
      response.is_a?(RTSP::Response).should be_true
    end
  end

  describe "#describe" do
    before do
      mock_socket = double 'MockSocket', :send => "", :recvfrom => [DESCRIBE_RESPONSE]
      mock_logger = double 'MockLogger', :send => nil
      @client = RTSP::Client.new "rtsp://localhost", :socket => mock_socket
      @client.logger = mock_logger
    end

    it "extracts the aggregate control track" do
      @client.describe
      @client.aggregate_control_track.should == "rtsp://64.202.98.91:554/gs.sdp/"
    end

    it "extracts the media control tracks" do
      @client.describe
      @client.media_control_tracks.should == ["rtsp://64.202.98.91:554/gs.sdp/trackID=1"]
    end

    it "increases @cseq by 1" do
      cseq_before = @client.instance_variable_get :@cseq
      @client.describe
      @client.instance_variable_get(:@cseq).should == cseq_before + 1
    end

    it "returns a Response" do
      response = @client.describe
      response.is_a?(RTSP::Response).should be_true
    end
  end
end