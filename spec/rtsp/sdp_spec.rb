require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'rtsp/sdp'

SDP_TEXT =<<EOF
v=0
o=jdoe 2890844526 2890842807 IN IP4 10.47.16.5
s=SDP Seminar
i=A Seminar on the session description protocol
u=http://www.example.com/seminars/sdp.pdf
e=j.doe@example.com (Jane Doe)
c=IN IP4 224.2.17.12/127
t=2873397496 2873404696
a=recvonly
m=audio 49170 RTP/AVP 0
m=video 51372 RTP/AVP 99
a=rtpmap:99 h263-1998/90000
EOF

describe SDP do
  context "parses SDP text into a Hash" do
    before do
      @parsed_sdp = SDP.parse_sdp SDP_TEXT
    end

    it "has a version number of 0" do
      @parsed_sdp[:version].should == "0"
      @parsed_sdp[:version].class.should == String
    end

    context "origin" do
      it "has a username of 'jdoe'" do
        @parsed_sdp[:origin][:username].should == 'jdoe'
        @parsed_sdp[:origin][:username].class.should == String
      end

      it "has a session_id of '2890844526'" do
        @parsed_sdp[:origin][:session_id].should == "2890844526"
        @parsed_sdp[:origin][:session_id].class.should == String
      end

      it "has a session_version of '2890842807'" do
        @parsed_sdp[:origin][:session_version].should == 2890842807
        @parsed_sdp[:origin][:session_version].class.should == Fixnum
      end

      it "has a net_type of 'IN'" do
        @parsed_sdp[:origin][:net_type].should == "IN"
        @parsed_sdp[:origin][:net_type].class.should == String
      end

      it "has a addr_type of 'IP4'" do
        @parsed_sdp[:origin][:addr_type].should == "IP4"
        @parsed_sdp[:origin][:addr_type].class.should == String
      end

      it "has a unicast_address of '10.47.16.5'" do
        @parsed_sdp[:origin][:unicast_address].should == "10.47.16.5"
        @parsed_sdp[:origin][:unicast_address].class.should == String
      end
    end

    it "has a session name of 'SDP Seminar'" do
      @parsed_sdp[:session_name].should == "SDP Seminar"
      @parsed_sdp[:session_name].class.should == String
    end

    it "has a session information of 'A Seminar on the session description protocol'" do
      @parsed_sdp[:session_information].should == "A Seminar on the session description protocol"
      @parsed_sdp[:session_information].class.should == String
    end

    it "has a URI of 'http://www.example.com/seminars/sdp.pdf'" do
      @parsed_sdp[:uri].to_s.should == "http://www.example.com/seminars/sdp.pdf"
      @parsed_sdp[:uri].class.should == String
    end

    it "has an email address of 'j.doe@example.com (Jane Doe)'" do
      @parsed_sdp[:email_address].should == "j.doe@example.com (Jane Doe)"
      @parsed_sdp[:email_address].class.should == String
    end

    it "does NOT have a phone number" do
      @parsed_sdp[:phone_number].should be_nil
    end

    context "connection data" do
      it "has a nettype of 'IN'" do
        @parsed_sdp[:connection_data][:net_type].should == 'IN'
        @parsed_sdp[:connection_data][:net_type].class.should == String
      end

      it "has a addrtype of 'IP4'" do
        @parsed_sdp[:connection_data][:addr_type].should == 'IP4'
        @parsed_sdp[:connection_data][:addr_type].class.should == String
      end

      it "has a connection address of '224.2.17.12/127'" do
        @parsed_sdp[:connection_data][:connection_address].should == '224.2.17.12/127'
        @parsed_sdp[:connection_data][:connection_address].class.should == String
      end
    end
  end

  context "SDP_VERSION" do
    it "has an SDP_VERSION constant defined" do
      SDP.const_defined?('SDP_VERSION').should be_true
    end

    it "is set to 0" do
      SDP::SDP_VERSION.should == 0
    end
  end

  context "creates SDP files" do
    before do
      @sdp = SDP.new
    end

    context "#initialize defaults" do
      it "initializes version to 0" do
        @sdp[:version].should == 0
      end

      context ":origin" do
        it "initializes :origin as a Hash" do
          @sdp[:origin].class.should == Hash
        end

        it "initializes :origin[:username] to be my username" do
          @sdp[:origin][:username].should == Etc.getlogin
        end

        it "initializes :origin[:session_id] to be an NTP timestamp" do
          @sdp[:origin][:session_id].class.should == Fixnum
        end

        it "initializes :origin[:session_version] to be an NTP timestamp" do
          @sdp[:origin][:session_version].class.should == Fixnum
        end

        it "initializes :origin[:net_type] to be 'IN'" do
          @sdp[:origin][:net_type].class.should == String
          @sdp[:origin][:net_type].should == "IN"
        end

        it "initializes :origin[:address_type] to be :IP4" do
          @sdp[:origin][:net_type].class.should == Symbol
          @sdp[:origin][:net_type].should == :IP4
        end
      end
    end
  end
end