=begin
adapted from
https://github.com/turboladen/rtsp
original copyright notice follows:

Copyright © 2011 sloveless, mkirby, nmccready

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the “Software”), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=end
require 'sdp'
require 'spec_helper'
require 'rtsp/client'

describe "Real Server (Wowza) Client use" do

  # block to show raw output for debugging
  def setup(url)
    response = subject.setup(@mediaUrl) do |transport|
      puts "SETUP RAW RESPONSE, Trasport: #{transport}"
      #by using a block we can now check the error location of the where the
      #problem begins
      #puts "Pre-ERROR @ RESPONSE #{transport[35]}"
      #puts "Pre-ERROR @ RESPONSE #{transport[36]}"
      #puts "ERROR @ RESPONSE #{transport[37]}"
    end
    return response
  end


  subject do
    #urls provided by rtsp client adroid app
    #alkass TV (updated)
    @baseUrl = "78.100.44.238" if @baseUrl.nil?
    @mediaUrl = "#{@baseUrl}/live-kass/kass" if @mediaUrl.nil?
    puts "RTSP: URL #{@baseUrl}!!!!!"
    puts "RTSP: Media URL #{@mediaUrl}!!!!!"
    RTSP::Client.new(@baseUrl)
  end

  describe "#options" do
    it "extracts the server's supported methods" do
      subject.options
      subject.supported_methods.should ==
        [:describe, :setup, :teardown, :play, :pause,
        :options,:announce,:record,:get_parameter]
    end

    it "returns a Response" do
      response = subject.options
      response.should be_a RTSP::Response
    end
  end

  #  describe "#describe" do
  #    before do
  #      puts "Before describe"
  #      @response = subject.describe
  #      puts "Response field = #{@response}"
  #    end
  #
  #      it "extracts the aggregate control track" do
  #        puts "Agg  #{subject.aggregate_control_track}"
  #          "rtsp://#{configatron.rtsp_server_wowza.url}/sa.sdp/"
  #      end
  #
  #      it "extracts the media control tracks" do
  #        subject.media_control_tracks.should == ["rtsp://64.202.98.91:554/sa.sdp/trackID=1"]
  #      end
  #
  #      it "extracts the SDP object" do
  #        subject.instance_variable_get(:@session_description).should ==
  #          @response.body
  #      end
  #
  #      it "extracts the Content-Base header" do
  #        subject.instance_variable_get(:@content_base).should ==
  #          URI.parse("rtsp://64.202.98.91:554/sa.sdp/")
  #      end
  #
  #     it "returns a Response" do
  #        @response.should be_a RTSP::Response
  #      end
  #    end

  describe "#announce" do
    it "returns a Response" do
      sdp = SDP::Description.new
      subject.setup(@mediaUrl)
      response = subject.announce(@mediaUrl, sdp)
      response.should be_a RTSP::Response
    end
  end

  describe "#setup" do
    after do
      subject.teardown(@mediaUrl)
    end

    it "extracts the session number" do
      subject.session.should be_empty
      setup(@mediaUrl)
      subject.session[:session_id].to_i.should >= 0
    end

    it "changes the session_state to :ready" do
      setup(@mediaUrl)
      subject.session_state.should == :ready
    end

    it "extracts the transport header info" do
      subject.instance_variable_get(:@transport).should be_nil
      setup(@mediaUrl)
      transport = subject.instance_variable_get(:@transport)
      #puts "HASH: transport = #{transport}"
      transport[:streaming_protocol].should == "RTP"
      transport[:profile].should == "AVP"
      transport[:broadcast_type].should == "unicast"
    end

    it "returns a Response" do
      response = setup(@mediaUrl)
      response.should be_a RTSP::Response
    end
  end

  #    describe "#play" do
  #      before do
  #        subject.setup(configatron.rtsp_server_wowza.media_url)
  #      end
  #
  #      after do
  #        subject.teardown(configatron.rtsp_server_wowza.media_url)
  #      end
  #
  #      it "changes the session_state to :playing" do
  #        subject.play(configatron.rtsp_server_wowza.media_url)
  #        subject.session_state.should == :playing
  #      end
  #
  #      it "returns a Response" do
  #        RTSP::Client.log = true
  #        RTP::Logger.log = true
  #        response = subject.play(configatron.rtsp_server_wowza.media_url)
  #        response.should be_a RTSP::Response
  #      end
  #    end
  #
  #  describe "#pause" do
  #    before :each do
  #      subject.setup("rtsp://localhost/some_track")
  #    end
  #
  #    after do
  #      subject.teardown('rtsp://localhost/some_track')
  #    end
  #
  #    it "changes the session_state from :playing to :ready" do
  #      subject.play("rtsp://localhost/some_track")
  #      subject.pause("rtsp://localhost/some_track")
  #      subject.session_state.should == :ready
  #    end
  #
  #    it "changes the session_state from :recording to :ready" do
  #      subject.record("rtsp://localhost/some_track")
  #      subject.pause("rtsp://localhost/some_track")
  #      subject.session_state.should == :ready
  #    end
  #
  #    it "returns a Response" do
  #      response = subject.pause("rtsp://localhost/some_track")
  #      response.should be_a RTSP::Response
  #    end
  #  end
  #
  #  describe "#teardown" do
  #    before do
  #      subject.setup("rtsp://localhost/some_track")
  #    end
  #
  #    it "changes the session_state to :init" do
  #      subject.session_state.should_not == :init
  #      subject.teardown("rtsp://localhost/some_track")
  #      subject.session_state.should == :init
  #    end
  #
  #    it "changes the session_id back to 0" do
  #      subject.session.should_not be_empty
  #      subject.teardown("rtsp://localhost/some_track")
  #      subject.session.should be_empty
  #    end
  #
  #    it "returns a Response" do
  #      response = subject.teardown("rtsp://localhost/some_track")
  #      response.should be_a RTSP::Response
  #    end
  #  end
  #
  #  describe "#get_parameter" do
  #    it "returns a Response" do
  #      response = subject.get_parameter("rtsp://localhost/some_track", "ping!")
  #      response.should be_a RTSP::Response
  #    end
  #  end
  #
  #  describe "#set_parameter" do
  #    it "returns a Response" do
  #      response = subject.set_parameter("rtsp://localhost/some_track", "ping!")
  #      response.should be_a RTSP::Response
  #    end
  #  end
  #
  #  describe "#record" do
  #    before :each do
  #      subject.setup("rtsp://localhost/some_track")
  #    end
  #
  #    after do
  #      subject.teardown('rtsp://localhost/some_track')
  #    end
  #
  #    it "returns a Response" do
  #      response = subject.record("rtsp://localhost/some_track")
  #      response.is_a?(RTSP::Response).should be_true
  #    end
  #
  #    it "changes the session_state to :recording" do
  #      subject.session_state.should == :ready
  #      subject.record("rtsp://localhost/some_track")
  #      subject.session_state.should == :recording
  #    end
  #  end
end
