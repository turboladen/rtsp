require 'sdp'
require_relative '../spec_helper'
require 'rtsp/client'
require 'support/fake_rtsp_server'

describe RTSP::Client do
  def setup_client_at(url)
    fake_rtsp_server = FakeRTSPServer.new
    mock_logger = double 'MockLogger', :send => nil

    client = RTSP::Client.new(url) do |connection|
      connection.socket = fake_rtsp_server
    end

    RTSP::Client.reset_config!
    RTSP::Client.configure { |config| config.log = false }
    client.logger = mock_logger

    client
  end

  before do
    RTSP::Capturer.any_instance.stub(:run)
    RTSP::Capturer.any_instance.stub(:stop)
  end

  describe "#initialize" do
    before :each do
      mock_socket = double 'MockSocket'
      @client = RTSP::Client.new("rtsp://localhost") do |connection|
        connection.socket = mock_socket
      end
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

      @client = RTSP::Client.new("rtsp://localhost") do |connection|
        connection.socket = mock_socket
      end
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
      @client = setup_client_at "rtsp://localhost"
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
      @client = setup_client_at "rtsp://localhost"
    end

    it "extracts the server's supported methods" do
      @client.options
      @client.supported_methods.should ==
          [:describe, :setup, :teardown, :play, :pause]
    end

    it "returns a Response" do
      response = @client.options
      response.is_a?(RTSP::Response).should be_true
    end
  end

  describe "#describe" do
    before do
      @client = setup_client_at "rtsp://localhost"
      @response = @client.describe
    end

    it "extracts the aggregate control track" do
      @client.aggregate_control_track.should == "rtsp://64.202.98.91:554/sa.sdp/"
    end

    it "extracts the media control tracks" do
      @client.media_control_tracks.should == ["rtsp://64.202.98.91:554/sa.sdp/trackID=1"]
    end

    it "extracts the SDP object" do
      @client.instance_variable_get(:@session_description).should ==
          @response.body
    end

    it "extracts the Content-Base header" do
      @client.instance_variable_get(:@content_base).should ==
          URI.parse("rtsp://64.202.98.91:554/sa.sdp/")
    end

    it "returns a Response" do
      @response.is_a?(RTSP::Response).should be_true
    end
  end

  describe "#announce" do
    it "returns a Response" do
      client = setup_client_at "rtsp://localhost"
      sdp = SDP::Description.new
      client.setup("rtsp://localhost/another_track")
      response = client.announce("rtsp://localhost/another_track", sdp)
      response.is_a?(RTSP::Response).should be_true
    end
  end

  describe "#setup" do
    before :each do
      @client = setup_client_at "rtsp://localhost"
    end

    it "extracts the session number" do
      @client.session.should be_zero
      @client.setup("rtsp://localhost/some_track")
      @client.session.should == 1234567890
    end

    it "changes the session_state to :ready" do
      @client.setup("rtsp://localhost/some_track")
      @client.session_state.should == :ready
    end

    it "extracts the transport header info" do
      @client.instance_variable_get(:@transport).should be_nil
      @client.setup("rtsp://localhost/some_track")
      @client.instance_variable_get(:@transport).should_not be_nil
    end

    it "returns a Response" do
      response = @client.setup("rtsp://localhost/some_track")
      response.is_a?(RTSP::Response).should be_true
    end
  end

  describe "#play" do
    before :each do
      @client = setup_client_at "rtsp://localhost"
    end

    after :each do
      @client.teardown "rtsp://localhost"
    end

    it "changes the session_state to :playing" do
      @client.setup("rtsp://localhost/some_track")
      @client.play("rtsp://localhost/some_track")
      @client.session_state.should == :playing
    end

    it "returns a Response" do
      @client.setup("rtsp://localhost/some_track")
      response = @client.play("rtsp://localhost/some_track")
      response.is_a?(RTSP::Response).should be_true
    end
  end

  describe "#pause" do
    before :each do
      @client = setup_client_at "rtsp://localhost"
      @client.setup("rtsp://localhost/some_track")
    end

    after :each do
      @client.teardown "rtsp://localhost"
    end

    it "changes the session_state from :playing to :ready" do
      @client.play("rtsp://localhost/some_track")
      @client.pause("rtsp://localhost/some_track")
      @client.session_state.should == :ready
    end

    it "changes the session_state from :recording to :ready" do
      @client.record("rtsp://localhost/some_track")
      @client.pause("rtsp://localhost/some_track")
      @client.session_state.should == :ready
    end

    it "returns a Response" do
      response = @client.pause("rtsp://localhost/some_track")
      response.is_a?(RTSP::Response).should be_true
    end
  end

  describe "#teardown" do
    before :each do
      @client = setup_client_at "rtsp://localhost"
      @client.setup("rtsp://localhost/some_track")
    end

    it "changes the session_state to :init" do
      @client.session_state.should_not == :init
      @client.teardown("rtsp://localhost/some_track")
      @client.session_state.should == :init
    end

    it "changes the session back to 0" do
      @client.session.should_not be_zero
      @client.teardown("rtsp://localhost/some_track")
      @client.session.should be_zero
    end
    
    it "returns a Response" do
      response = @client.teardown("rtsp://localhost/some_track")
      response.is_a?(RTSP::Response).should be_true
    end
  end

  describe "#get_parameter" do
    before :each do
      @client = setup_client_at "rtsp://localhost"
    end

    it "returns a Response" do
      response = @client.get_parameter("rtsp://localhost/some_track", "ping!")
      response.is_a?(RTSP::Response).should be_true
    end
  end

  describe "#set_parameter" do
    before :each do
      @client = setup_client_at "rtsp://localhost"
    end

    it "returns a Response" do
      response = @client.set_parameter("rtsp://localhost/some_track", "ping!")
      response.is_a?(RTSP::Response).should be_true
    end
  end

  describe "#record" do
    before :each do
      @client = setup_client_at "rtsp://localhost"
      @client.setup("rtsp://localhost/some_track")
    end

    it "returns a Response" do
      response = @client.record("rtsp://localhost/some_track")
      response.is_a?(RTSP::Response).should be_true
    end

    it "changes the session_state to :recording" do
      @client.session_state.should == :ready
      @client.record("rtsp://localhost/some_track")
      @client.session_state.should == :recording
    end
  end

  describe "#send_message" do
    it "raises if the send takes longer than the timeout" do
      pending "until I figure out how to test the time out raises"
      @client = setup_client_at "rtsp://localhost"
    end
  end
end
