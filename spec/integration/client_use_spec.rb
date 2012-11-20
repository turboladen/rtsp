require 'sdp'
require 'spec_helper'
require 'rtsp/client'

describe "Client use" do
  subject do
    fake_rtsp_server = FakeRTSPServer.new

    RTSP::Client.new('http://localhost') do |connection|
      connection.socket = fake_rtsp_server
    end
  end

  describe "#options" do
    it "extracts the server's supported methods" do
      subject.options
      subject.supported_methods.should ==
        [:describe, :setup, :teardown, :play, :pause]
    end

    it "returns a Response" do
      response = subject.options
      response.should be_a RTSP::Response
    end
  end

  describe "#describe" do
    before do
      @response = subject.describe
    end

    it "extracts the aggregate control track" do
      subject.aggregate_control_track.should == "rtsp://64.202.98.91:554/sa.sdp/"
    end

    it "extracts the media control tracks" do
      subject.media_control_tracks.should == ["rtsp://64.202.98.91:554/sa.sdp/trackID=1"]
    end

    it "extracts the SDP object" do
      subject.instance_variable_get(:@session_description).should ==
        @response.body
    end

    it "extracts the Content-Base header" do
      subject.instance_variable_get(:@content_base).should ==
        URI.parse("rtsp://64.202.98.91:554/sa.sdp/")
    end

    it "returns a Response" do
      @response.should be_a RTSP::Response
    end
  end

  describe "#announce" do
    it "returns a Response" do
      sdp = SDP::Description.new
      subject.setup("rtsp://localhost/another_track")
      response = subject.announce("rtsp://localhost/another_track", sdp)
      response.should be_a RTSP::Response
    end
  end

  describe "#setup" do
    after do
      subject.teardown("rtsp://localhost/some_track")
    end

    it "extracts the session number" do
      subject.session.should be_empty
      subject.setup("rtsp://localhost/some_track")
      subject.session[:session_id].should == "1234567890"
    end

    it "changes the session_state to :ready" do
      subject.setup("rtsp://localhost/some_track")
      subject.session_state.should == :ready
    end

    it "extracts the transport header info" do
      subject.instance_variable_get(:@transport).should be_nil
      subject.setup("rtsp://localhost/some_track")
      subject.instance_variable_get(:@transport).should == {
        streaming_protocol: "RTP",
        profile: "AVP",
        broadcast_type: "unicast",
        destination: "127.0.0.1",
        source: "10.221.222.235",
        client_port: { rtp: "9000", rtcp: "9001" },
        server_port: { rtp: "6700", rtcp: "6701" }
      }
    end

    it "returns a Response" do
      response = subject.setup("rtsp://localhost/some_track")
      response.should be_a RTSP::Response
    end
  end

  describe "#play" do
    before do
      subject.setup("rtsp://localhost/some_track")
    end

    after do
      subject.teardown('rtsp://localhost/some_track')
    end

    it "changes the session_state to :playing" do
      subject.play("rtsp://localhost/some_track")
      subject.session_state.should == :playing
    end

    it "returns a Response" do
      RTSP::Client.log = true
      RTP::Logger.log = true
      response = subject.play("rtsp://localhost/some_track")
      response.should be_a RTSP::Response
    end
  end

  describe "#pause" do
    before :each do
      subject.setup("rtsp://localhost/some_track")
    end

    after do
      subject.teardown('rtsp://localhost/some_track')
    end

    it "changes the session_state from :playing to :ready" do
      subject.play("rtsp://localhost/some_track")
      subject.pause("rtsp://localhost/some_track")
      subject.session_state.should == :ready
    end

    it "changes the session_state from :recording to :ready" do
      subject.record("rtsp://localhost/some_track")
      subject.pause("rtsp://localhost/some_track")
      subject.session_state.should == :ready
    end

    it "returns a Response" do
      response = subject.pause("rtsp://localhost/some_track")
      response.should be_a RTSP::Response
    end
  end

  describe "#teardown" do
    before do
      subject.setup("rtsp://localhost/some_track")
    end

    it "changes the session_state to :init" do
      subject.session_state.should_not == :init
      subject.teardown("rtsp://localhost/some_track")
      subject.session_state.should == :init
    end

    it "changes the session_id back to 0" do
      subject.session.should_not be_empty
      subject.teardown("rtsp://localhost/some_track")
      subject.session.should be_empty
    end

    it "returns a Response" do
      response = subject.teardown("rtsp://localhost/some_track")
      response.should be_a RTSP::Response
    end
  end

  describe "#get_parameter" do
    it "returns a Response" do
      response = subject.get_parameter("rtsp://localhost/some_track", "ping!")
      response.should be_a RTSP::Response
    end
  end

  describe "#set_parameter" do
    it "returns a Response" do
      response = subject.set_parameter("rtsp://localhost/some_track", "ping!")
      response.should be_a RTSP::Response
    end
  end

  describe "#record" do
    before :each do
      subject.setup("rtsp://localhost/some_track")
    end

    after do
      subject.teardown('rtsp://localhost/some_track')
    end

    it "returns a Response" do
      response = subject.record("rtsp://localhost/some_track")
      response.is_a?(RTSP::Response).should be_true
    end

    it "changes the session_state to :recording" do
      subject.session_state.should == :ready
      subject.record("rtsp://localhost/some_track")
      subject.session_state.should == :recording
    end
  end
end
