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
      before { @capturer = RTSP::Capturer.new }

      it "uses UDP" do
        @capturer.instance_variable_get(:@transport_protocol).should == :UDP
      end

      it "uses port 9000" do
        @capturer.instance_variable_get(:@rtp_port).should == 9000
      end

      it "creates a new Tempfile" do
        @capturer.instance_variable_get(:@rtp_file).should be_a Tempfile
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
    after :each do
      @capturer.stop
    end

    it "creates a UDPSocket when initialized with :UDP" do
      @capturer = RTSP::Capturer.new
      @capturer.init_server(:UDP).should be_a UDPSocket
    end

    it "creates a TCPSocket when initialized with :TCP" do
      TCPServer.new('0.0.0.0', 9000)
      @capturer = RTSP::Capturer.new
      @capturer.init_server(:TCP).should be_a TCPSocket
    end
  end

  describe "#run" do
    context "default capturer settings" do
      before do
        @capturer = RTSP::Capturer.new
        @receiver_thread = Thread.start(@capturer) { |capturer| capturer.run }

        @client = UDPSocket.open
        @sender_thread = Thread.start(@client) do |client|
          loop do
            client.send "x", 0, 'localhost', @capturer.rtp_port
          end
        end

        sleep 0.1
      end

      after do
        @sender_thread.exit
        @receiver_thread.exit
      end

      it "gets access to a UDPSocket via @server" do
        @capturer.instance_variable_get(:@server).should be_a UDPSocket
      end

      it "sets @run to true" do
        @capturer.instance_variable_get(:@run).should be_true
      end

      it "receives data and writes to @rtp_file" do
        @capturer.rtp_file.size.should > 0
      end

      it "closes the @server after issuing a #stop" do
        @capturer.instance_variable_get(:@server).should_not be_closed
        @capturer.stop
        sleep 0.1
        @capturer.instance_variable_get(:@server).should be_closed
      end
    end
  end

  describe "#running?" do
    before { @capturer = RTSP::Capturer.new }

    it "returns false before issuing #run" do
      @capturer.running?.should be_false
    end

    it "returns true after running" do
      cap_thread = Thread.new(@capturer) { |capturer| capturer.run }
      sleep 0.1
      @capturer.running?.should be_true
      cap_thread.exit
    end

    it "returns false after running, then stopping" do
      cap_thread = Thread.new(@capturer) { |capturer| capturer.run }
      sleep 0.1
      @capturer.running?.should be_true
      @capturer.stop
      @capturer.running?.should be_false
      cap_thread.exit
    end
  end

  describe "#stop" do
    before { @capturer = RTSP::Capturer.new }

    context "not running yet" do
      it "sets @run to false" do
        @capturer.stop
        @capturer.instance_variable_get(:@run).should == false
      end
    end

    context "running" do
      it "sets @run to false" do
        Thread.new(@capturer) { |c| c.run }
        sleep 0.1
        @capturer.stop
        @capturer.instance_variable_get(:@run).should == false
      end
    end
  end

  describe "#init_udp_server" do
    after :each do
      unless @sockets.nil?
        @sockets.each { |s| s.close }
      end
    end

    it "returns a UDPSocket" do
      capturer = RTSP::Capturer.new
      server = capturer.init_udp_server(capturer.rtp_port)
      server.should be_a UDPSocket
    end

    it "retries MAX_PORT_NUMBER_RETRIES to get a port" do
      @sockets = use_udp_ports 9000...(9000 + RTSP::Capturer::MAX_PORT_NUMBER_RETRIES)
      #@sockets.each { |s| puts "meow: #{s.addr[1]}" }

      capturer = RTSP::Capturer.new
      capturer.init_udp_server(capturer.rtp_port)
      capturer.rtp_port.should == 9000 + RTSP::Capturer::MAX_PORT_NUMBER_RETRIES
    end

    context "when no available ports, it retries MAX_PORT_NUMBER_RETRIES times, then" do
      before do
        @sockets = use_udp_ports 9000..(9000 + RTSP::Capturer::MAX_PORT_NUMBER_RETRIES)

        @capturer = RTSP::Capturer.new
      end

      it "retries MAX_PORT_NUMBER_RETRIES times then raises" do
        expect { @capturer.init_udp_server(@capturer.rtp_port) }.to raise_error Errno::EADDRINUSE
      end

      it "sets @rtp_port back to 9000 after trying all" do
        expect { @capturer.init_udp_server(@capturer.rtp_port) }.to raise_error Errno::EADDRINUSE
        @capturer.rtp_port.should == 9000
      end
    end
  end

  describe "#init_tcp_server" do
    before do
      @capturer = RTSP::Capturer.new(:TCP)
      @server = @capturer.init_tcp_server(@capturer.rtp_port)
    end

    it "returns a TCPSocket" do
      @server.should be_a TCPSocket
    end

    it "uses port a port between 9000 and 9000 + MAX_PORT_NUMBER_RETRIES" do
      @capturer.rtp_port.should >= 9000
      @capturer.rtp_port.should <= 9000 + RTSP::Capturer::MAX_PORT_NUMBER_RETRIES
    end
  end
end
