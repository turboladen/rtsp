require_relative '../spec_helper'
require 'rtsp/transport_parser'

describe RTSP::TransportParser do
  before do
    @parser = RTSP::TransportParser.new
  end

  describe "a basic Transport header" do
    before do
      transport = "RTP/AVP;unicast;client_port=9000-9001"
      @result = @parser.parse transport
    end

    it "extracts the protocol" do
      @result[:streaming_protocol].should == 'RTP'
    end

    it "extracts the profile" do
      @result[:profile].should == 'AVP'
    end

    it "extracts the broadcast type" do
      @result[:broadcast_type].should == 'unicast'
    end

    it "extracts the client RTP port" do
      @result[:client_port][:rtp].should == '9000'
    end

    it "extracts the client RTCP port" do
      @result[:client_port][:rtcp].should == '9001'
    end
  end

  describe "a TCP binary interleaved Transport header" do
    before do
      transport = "RTP/AVP/TCP;unicast;interleaved=0-1"
      @result = @parser.parse transport
    end

    it "extracts the lower transport type" do
      @result[:transport_protocol].should == 'TCP'
    end

    it "extracts the interleaved RTP channel" do
      @result[:interleaved][:rtp_channel].should == '0'
    end

    it "extracts the interleaved RTCP channel" do
      @result[:interleaved][:rtcp_channel].should == '1'
    end
  end
end
