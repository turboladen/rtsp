require 'spec_helper'
require 'rtsp/transport_parser'

describe RTSP::TransportParser do
  let(:result) { subject.parse transport }

  describe :transport_specifier do
    context "RTP/AVP" do
      let(:transport) { "RTP/AVP" }
      specify { result[:streaming_protocol].should == 'RTP' }
      specify { result[:profile].should == 'AVP' }
    end

    context "RTP/AVP/TCP" do
      let(:transport) { "RTP/AVP/TCP" }
      specify { result[:streaming_protocol].should == 'RTP' }
      specify { result[:profile].should == 'AVP' }
      specify { result[:transport_protocol].should == 'TCP' }
    end

    context "rtp/avp/tcp" do
      let(:transport) { "rtp/avp/tcp" }
      specify { result[:streaming_protocol].should == 'rtp' }
      specify { result[:profile].should == 'avp' }
      specify { result[:transport_protocol].should == 'tcp' }
    end
  end

  describe :broadcast_type do
    context "RTP/AVP;unicast" do
      let(:transport) { "RTP/AVP;unicast" }
      specify { result[:broadcast_type].should == 'unicast' }
    end

    context "RTP/AVP;multicast" do
      let(:transport) { "RTP/AVP;multicast" }
      specify { result[:broadcast_type].should == 'multicast' }
    end
  end

  describe :destination do
    context "RTP/AVP;multicast;destination=224.2.0.1" do
      let(:transport) { "RTP/AVP;multicast;destination=224.2.0.1" }
      specify { result[:destination].should == '224.2.0.1' }
    end
  end

  describe :source do
    context "RTP/AVP;multicast;destination=22.2.0.1;source=10.0.0.10" do
      let(:transport) { "RTP/AVP;multicast;destination=22.2.0.1;source=10.0.0.10" }
      specify { result[:source].should == '10.0.0.10' }
    end
  end

  describe :client_port do
    context "RTP/AVP;unicast;client_port=9000-9001" do
      let(:transport) { "RTP/AVP;unicast;client_port=9000-9001" }
      specify { result[:client_port][:rtp].should == '9000' }
      specify { result[:client_port][:rtcp].should == '9001' }
    end
  end

  describe :server_port do
    context "RTP/AVP/UCP;unicast;client_port=3058-3059;server_port=5002-5003" do
      let(:transport) { "RTP/AVP/UCP;unicast;client_port=3058-3059;server_port=5002-5003" }
      specify { result[:server_port][:rtp].should == "5002" }
      specify { result[:server_port][:rtcp].should == "5003" }
    end
  end

  describe :interleaved do
    context "RTP/AVP/TCP;unicast;interleaved=0-1" do
      let(:transport) { "RTP/AVP/TCP;unicast;interleaved=0-1" }
      specify { result[:interleaved][:rtp_channel].should == '0' }
      specify { result[:interleaved][:rtcp_channel].should == '1' }
    end
  end

  describe :ttl do
    context 'RTP/AVP;unicast;ttl=127' do
      let(:transport) { 'RTP/AVP;unicast;ttl=127' }
      specify { result[:ttl].should == "127" }
    end
  end

  describe :port do
    context 'RTP/AVP;unicast;port=1234' do
      let(:transport) { 'RTP/AVP;unicast;port=1234' }
      specify { result[:port][:rtp].should == "1234" }
      specify { result[:port][:rtcp].should be_nil }
    end

    context 'RTP/AVP;unicast;port=1234-1235' do
      let(:transport) { 'RTP/AVP;unicast;port=1234-1235' }
      specify { result[:port][:rtp].should == "1234" }
      specify { result[:port][:rtcp].should == "1235" }
    end
  end

  describe :ssrc do
    context 'RTP/AVP;unicast;ssrc=ABCD1234' do
      let(:transport) { 'RTP/AVP;unicast;ssrc=ABCD1234' }
      specify { result[:ssrc].should == "ABCD1234" }
    end
  end

  describe :channel do
    context 'RTP/AVP;unicast;channel=RTP' do
      let(:transport) { 'RTP/AVP;unicast;channel=RTP' }
      specify { result[:channel].should == "RTP" }
    end
  end

  describe :address do
    context 'RTP/AVP;unicast;address=192.168.14.18' do
      let(:transport) { 'RTP/AVP;unicast;address=192.168.14.18' }
      specify { result[:address].should == "192.168.14.18" }
    end

    context 'RTP/AVP;unicast;address=mycomputer.com' do
      let(:transport) { 'RTP/AVP;unicast;address=mycomputer.com' }
      specify { result[:address].should == "mycomputer.com" }
    end
  end

  describe :mode do
    context 'RTP/AVP;unicast;mode="PLAY"' do
      let(:transport) { 'RTP/AVP;unicast;mode="PLAY"' }
      specify { result[:mode].should == "PLAY" }
    end

    context 'with ttl=127;mode=RECORD' do
      let(:transport) { 'RTP/AVP;unicast;mode=RECORD' }
      specify { result[:mode].should == "RECORD" }
    end
  end
end
