require_relative '../spec_helper'
require 'rtsp/capturer'

Thread.abort_on_exception = true

def use_udp_ports(range)
  sockets = []

  range.each do |port|
    begin
      socket = UDPSocket.open
      socket.bind('0.0.0.0', port)
      sockets << socket
    rescue Errno::EADDRINUSE
      # That's ok
    end
  end

  sockets
end

describe RTSP::Capturer do
  before do
    if defined? RTSP::Client
      RTSP::Client.log = false
    end
  end

  describe "#initialize" do
    context "with default parameters" do
      it "uses UDP" do
        subject.instance_variable_get(:@transport_protocol).should == :UDP
      end

      it "uses port 9000" do
        subject.instance_variable_get(:@rtp_port).should == 9000
      end

      it "creates a new Tempfile" do
        subject.instance_variable_get(:@rtp_file).should be_a Tempfile
      end
    end

    context "non-default parameters" do
      it "can use TCP" do
        capturer = RTSP::Capturer.new(:TCP)
        capturer.instance_variable_get(:@transport_protocol).should == :TCP
      end

      it "can take another port" do
        capturer = RTSP::Capturer.new(:UDP, 12345)
        capturer.instance_variable_get(:@rtp_port).should == 12345
      end

      it "can take an IO object" do
        fd = IO.sysopen("/dev/null", "w")
        io = IO.new(fd, 'w')
        capturer = RTSP::Capturer.new(:UDP, 12345, io)
        capturer.instance_variable_get(:@rtp_file).should be_a IO
      end
    end

    it "isn't running" do
      RTSP::Capturer.new.should_not be_running
    end
  end

  describe "#init_server" do
    context "UDP" do
      it "calls #init_udp_server with port 9000" do
        subject.should_receive(:init_udp_server).with(9000)
        subject.init_server(:UDP)
      end

      it "returns a UDPSocket" do
        subject.init_server(:UDP).should be_a(UDPSocket)
      end
    end

    context "TCP" do
      it "calls #init_tcp_server with port 9000" do
        subject.should_receive(:init_tcp_server).with(9000)
        subject.init_server(:TCP)
      end

      it "returns a TCPServer" do
        subject.init_server(:TCP).should be_a(TCPServer)
      end
    end

    it "raises an RTSP::Error when some other protocol is given" do
      expect { subject.init_server(:BOBO) }.to raise_error RTSP::Error
    end
  end

  describe "#init_udp_server" do
    after :each do
      unless @sockets.nil?
        @sockets.each { |s| s.close }
      end
    end

    it "returns a UDPSocket" do
      server = subject.init_udp_server(subject.rtp_port)
      server.should be_a UDPSocket
    end

    it "retries MAX_PORT_NUMBER_RETRIES to get a port" do
      @sockets = use_udp_ports 9000...(9000 + RTSP::Capturer::MAX_PORT_NUMBER_RETRIES)
      subject.init_udp_server(subject.rtp_port)

      subject.rtp_port.should == 9000 + RTSP::Capturer::MAX_PORT_NUMBER_RETRIES
    end

    context "when no available ports, it retries MAX_PORT_NUMBER_RETRIES times, then" do
      before do
        @sockets = use_udp_ports 9000..(9000 + RTSP::Capturer::MAX_PORT_NUMBER_RETRIES)
      end

      it "retries MAX_PORT_NUMBER_RETRIES times then raises" do
        expect { subject.init_udp_server(subject.rtp_port) }.to raise_error Errno::EADDRINUSE
      end

      it "sets @rtp_port back to 9000 after trying all" do
        expect { subject.init_udp_server(subject.rtp_port) }.to raise_error Errno::EADDRINUSE
        subject.rtp_port.should == 9000
      end
    end
  end

  describe "#init_tcp_server" do
    it "returns a TCPSocket" do
      subject.init_tcp_server(3456).should be_a TCPSocket
    end

    it "uses port a port between 9000 and 9000 + MAX_PORT_NUMBER_RETRIES" do
      subject.init_tcp_server(9000)
      subject.rtp_port.should >= 9000
      subject.rtp_port.should <= 9000 + RTSP::Capturer::MAX_PORT_NUMBER_RETRIES
    end
  end

  describe "#run" do
    after(:each) { subject.stop }

    it "calls #start_file_builder and #start_listener" do
      subject.should_receive(:start_listener)
      subject.should_receive(:start_file_builder)
      subject.run
    end
  end

  describe "#running?" do
    after(:each) { subject.stop }

    it "returns false before issuing #run" do
      subject.running?.should be_false
    end

    it "returns true after running" do
      subject.run
      subject.running?.should be_true
    end

    it "returns false after running then stopping" do
      subject.run
      subject.running?.should be_true
      subject.stop
      subject.running?.should be_false
    end
  end

  describe "#stop" do
    it "calls #stop_listener" do
      subject.should_receive(:stop_listener)
      subject.stop
    end

    it "calls #stop_file_builder" do
      subject.should_receive(:stop_file_builder)
      subject.stop
    end

    it "sets @queue back to a new Queue" do
      queue = subject.instance_variable_get(:@queue)
      subject.stop
      subject.instance_variable_get(:@queue).should_not equal queue
      subject.instance_variable_get(:@queue).should_not be_nil
    end
  end

  [
    {
      start_method: "start_file_builder",
      stop_method: "stop_file_builder",
      ivar: "@file_builder"
    },
      {
        start_method: "start_listener",
        stop_method: "stop_listener",
        ivar: "@listener"
      }
  ].each do |method_set|
    describe "##{method_set[:start_method]}" do
      before(:each) do
        rtp_file = double "rtp_file"
        rtp_file.stub(:write)
        subject.rtp_file = rtp_file

        server = double "A Server"
        server.stub_chain(:recvfrom, :first).and_return("not nil")
        subject.stub(:init_server).and_return(server)
      end

      after(:each) { subject.send(method_set[:stop_method].to_sym) }

      it "starts the #{method_set[:ivar]} thread" do
        subject.send(method_set[:start_method])
        subject.instance_variable_get(method_set[:ivar].to_sym).should be_a Thread
      end

      it "returns the same #{method_set[:ivar]} if already started" do
        subject.send(method_set[:start_method])
        original_ivar = subject.instance_variable_get(method_set[:ivar].to_sym)
        new_ivar = subject.send method_set[:start_method].to_sym
        original_ivar.should equal new_ivar
      end

      if method_set[:start_method] == "start_listener"
        it "pushes data on to the @queue" do
          subject.start_listener
          subject.instance_variable_get(:@queue).pop.should == "not nil"
        end
      end
    end

    describe "##{method_set[:stop_method]}" do
      context "#{method_set[:ivar]} thread is running" do
        before { subject.send(method_set[:start_method]) }

        it "kills the thread" do
          original_ivar = subject.instance_variable_get(method_set[:ivar].to_sym)
          original_ivar.should_receive(:kill)
          subject.send(method_set[:stop_method])
        end
      end

      context "#{method_set[:ivar]} thread isn't running" do
        it "doesn't try to kill the thread" do
          allow_message_expectations_on_nil
          original_ivar = subject.instance_variable_get(method_set[:ivar].to_sym)
          original_ivar.should_not_receive(:kill)
          subject.send(method_set[:stop_method])
        end
      end
    end
  end
end
