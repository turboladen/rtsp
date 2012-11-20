require_relative '../spec_helper'
require 'rtsp/client'

RTSP::Client.log = false
RTP::Logger.log = false


describe RTSP::Client do
  subject do
    mock_socket = double 'MockSocket'

    RTSP::Client.new("rtsp://localhost") do |connection|
      connection.socket = mock_socket
    end
  end

  describe "#initialize" do
    it "sets cseq to 1" do
      subject.cseq.should == 1
    end

    it "sets session_state to :init" do
      subject.session_state.should == :init
    end

    it "sets server_uri to be a URI containing the first init param + 554" do
      subject.server_uri.should be_a(URI)
      subject.server_uri.to_s.should == "rtsp://localhost:554"
    end
  end

  describe ".configure" do
    around do |example|
      RTSP::Client.reset_config!
      example.run
      RTSP::Client.reset_config!
      RTSP::Client.log = false
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

  describe "#server_url" do
    it "allows for changing the server URL on the fly" do
      subject.server_uri.to_s.should == "rtsp://localhost:554"
      subject.server_url = "rtsp://localhost:8080"
      subject.server_uri.to_s.should == "rtsp://localhost:8080"
      subject.server_uri.should be_a URI
    end

    it "raises when passing in something other than a String" do
      subject.server_uri.to_s.should == "rtsp://localhost:554"
      expect { subject.server_url = [] }.to raise_error
    end
  end

  describe "#options" do
    let(:message) do
      m = double "RTSP::Message"
      m.should_receive(:with_headers).with(cseq: 1).and_return m
      m.should_receive(:add_headers).with({})

      m
    end

    let(:response) do
      double "RTSP::Response", public: [:a_method]
    end

    it "creates a RTSP::Message.options from @server_uri" do
      RTSP::Message.should_receive(:options).with('rtsp://localhost:554').
        and_return message
      subject.should_receive(:request).with(message).and_yield(response)
      subject.should_receive(:extract_supported_methods_from).with [:a_method]
      subject.options
    end
  end

  describe "#describe" do
    let(:message) do
      m = double "RTSP::Message"
      m.should_receive(:with_headers).with(cseq: 1).and_return m
      m.should_receive(:add_headers).with({})

      m
    end

    let(:response) do
      r = double "RTSP::Response"
      r.should_receive(:body).and_return "the body"
      r.should_receive(:content_base).and_return "content"

      r
    end

    before do
      RTSP::Message.should_receive(:describe).with('rtsp://localhost:554').
        and_return message
      subject.should_receive(:request).with(message).and_yield(response)
      subject.should_receive(:build_resource_uri_from).with("content").
        and_return "content"
      subject.should_receive(:media_control_tracks).and_return 'media'
      subject.should_receive(:aggregate_control_track).and_return 'aggregate'

      subject.describe
    end

    it "extracts @session_description, @content_base, and tracks" do
      subject.instance_variable_get(:@session_description).should == 'the body'
      subject.instance_variable_get(:@content_base).should == 'content'
      subject.instance_variable_get(:@media_control_tracks).should == 'media'
      subject.instance_variable_get(:@aggregate_control_track).should == 'aggregate'
    end
  end

  describe "#announce" do
    let(:message) do
      message = double "RTSP::Message"
      message.should_receive(:with_headers).with(cseq: 1).and_return message
      message.should_receive(:add_headers).with({})
      message.should_receive(:body=).with('description')

      message
    end

    let(:description) { double "SDP::Description", to_s: "description" }
    let(:url) { 'rtsp://neato:9000' }

    it "creates and sends an announce request with request_url and description" do
      RTSP::Message.should_receive(:announce).with(url).and_return message
      subject.should_receive(:request).with(message)
      subject.announce(url, description)
    end
  end

  describe "#setup" do
    let(:message) do
      subject.stub(:request_transport).and_return "transport"
      message = double "RTSP::Message"
      message.should_receive(:with_headers).
        with(cseq: 1, transport: "transport").and_return message
      message.should_receive(:add_headers).with({})

      message
    end

    let(:track_url) { 'rtsp://server/track1' }
    let(:response) do
      r = double "RTSP::Response"
      r.should_receive(:session).and_return session
      r.should_receive(:transport).and_return transport

      r
    end

    let(:transport) do
      t = double "@transport"
      t.should_receive(:[]).with(:transport_protocol).twice.and_return "RTP"
      t.stub_chain(:[], :[]).and_return 1
      t.should_receive(:[]).with(:destination).and_return "destination"

      t
    end

    let(:transport_parser) { double "RTSP::TransportParser", parse: transport }
    let(:session) { 1 }

    before do
      RTSP::Message.should_receive(:setup).with(track_url).and_return message
      subject.should_receive(:request).with(message).and_yield response
      RTSP::TransportParser.stub(:new).and_return transport_parser

      subject.setup(track_url)
    end

    it "changes session_state to :ready" do
      subject.session_state.should == :ready
    end

    it "sets the capturer's transport_protocol to what was requested in the transport header" do
      subject.capturer.transport_protocol.should == "RTP"
    end

    it "sets the capturer's rtp_port to what was requested in the transport header" do
      subject.capturer.rtp_port.should == 1
    end

    it "sets the capturer's ip_address to what was requested in the transport header" do
      subject.capturer.ip_address.should == "destination"
    end
  end

  describe "#play" do
    let(:fake_capturer) { double "RTP::Receiver" }

    let(:transport) do
      t = double "@transport"
      t.stub_chain(:[], :[])

      t
    end

    before do
      subject.capturer = fake_capturer
      subject.instance_variable_set(:@transport, transport)
      subject.instance_variable_set(:@session_state, :ready)
      subject.should_receive(:request).and_yield
    end

    context "@session_state is :ready" do
      before do
        fake_capturer.should_receive(:start)
      end

      it "changes the session_state to :playing" do
        subject.play("rtsp://localhost/some_track")

        subject.session_state.should == :playing
      end
    end

    context "@session_state is not :ready" do
      before do
        subject.instance_variable_set(:@session_state, :pants)
      end

      it "raises an error" do
        expect {
          subject.play("rtsp://localhost/some_track")
        }.to raise_error RTSP::Error
      end
    end
  end

  describe "#pause" do
    let(:message) do
      m = double "RTSP::Message"
      m.should_receive(:with_headers).with(cseq: 1, session: 1).and_return m
      m.should_receive(:add_headers).with({})

      m
    end

    before do
      RTSP::Message.should_receive(:pause).and_return message
      subject.instance_variable_set(:@session, { session_id: 1 })
      subject.should_receive(:request).with(message).and_yield
    end

    context "@session_state is :playing" do
      before do
        subject.instance_variable_set(:@session_state, :playing)

        subject.pause('rtsp://localhost/some_track')
      end

      it "sets @session_state to :ready" do
        subject.instance_variable_get(:@session_state).should == :ready
      end
    end

    context "@session_state is not :playing" do
      before do
        subject.instance_variable_set(:@session_state, :pants)

        subject.pause('rtsp://localhost/some_track')
      end

      it "doesn't change @session_state" do
        subject.instance_variable_get(:@session_state).should == :pants
      end
    end
  end

  describe "#teardown" do
    let(:message) do
      m = double "RTSP::Message"
      m.should_receive(:with_headers).with(cseq: 1, session: 1).and_return m
      m.should_receive(:add_headers).with({})

      m
    end

    before do
      RTSP::Message.should_receive(:teardown).and_return message
      subject.instance_variable_set(:@session, { session_id: 1 })
      subject.instance_variable_set(:@session_state, :playing)
      subject.should_receive(:request).with(message).and_yield
      subject.capturer.should_receive(:stop)

      subject.teardown('rtsp://localhost/some_track')
    end

    it "sets @session_state back to :init" do
      subject.instance_variable_get(:@session_state).should == :init
    end

    it "clears the session info" do
      subject.instance_variable_get(:@session).should == {}
    end
  end

  describe "#get_parameter" do
    let(:message) do
      m = double "RTSP::Message"
      m.should_receive(:with_headers).with(cseq: 1).and_return m
      m.should_receive(:add_headers).with({})
      m.should_receive(:body=).with(body)

      m
    end

    let(:body) { "body" }

    it "sends the request" do
      RTSP::Message.should_receive(:get_parameter).and_return message
      subject.should_receive(:request).with(message)

      subject.get_parameter('rtsp://localhost/some_track', body)
    end
  end

  describe "#set_parameter" do
    let(:message) do
      m = double "RTSP::Message"
      m.should_receive(:with_headers).with(cseq: 1).and_return m
      m.should_receive(:add_headers).with({})
      m.should_receive(:body=).with(body)

      m
    end

    let(:body) { "body" }

    it "sends the request" do
      RTSP::Message.should_receive(:set_parameter).and_return message
      subject.should_receive(:request).with(message)

      subject.set_parameter('rtsp://localhost/some_track', body)
    end
  end

  describe "#record" do
    let(:message) do
      m = double "RTSP::Message"
      m.should_receive(:with_headers).with(cseq: 1, session: 1).and_return m
      m.should_receive(:add_headers).with({})

      m
    end

    before do
      RTSP::Message.should_receive(:record).and_return message
      subject.instance_variable_set(:@session, { session_id: 1 })
      subject.instance_variable_set(:@session_state, :playing)
      subject.should_receive(:request).with(message).and_yield

      subject.record('rtsp://localhost/some_track')
    end

    it "sets @session_state to :recording" do
      subject.instance_variable_get(:@session_state).should == :recording
    end
  end

  describe "#send_message" do
    it "raises if the send takes longer than the timeout" do
      pending "until I figure out how to test the time out raises"
    end
  end
end
