require 'spec_helper'
require 'rtsp/helpers'

class HelperTest
  include RTSP::Helpers
end

describe RTSP::Helpers do
  describe "#build_resource_uri_from" do
    before do
      @my_object = HelperTest.new
    end

    context "parses the resource URL to a URI" do
      it "with scheme, IP, path; port defaults to 554" do
        uri = @my_object.build_resource_uri_from "rtsp://64.202.98.91/sa.sdp"
        uri.scheme.should == "rtsp"
        uri.host.should == "64.202.98.91"
        uri.port.should == 554
        uri.path.should == "/sa.sdp"
      end

      it "with IP, path; port defaults to 554; scheme defaults to 'rtsp'" do
        uri = @my_object.build_resource_uri_from "64.202.98.91/sa.sdp"
        uri.scheme.should == "rtsp"
        uri.host.should == "64.202.98.91"
        uri.port.should == 554
        uri.path.should == "/sa.sdp"
      end

      it "with scheme, IP, port" do
        uri = @my_object.build_resource_uri_from "rtsp://64.202.98.91"
        uri.scheme.should == "rtsp"
        uri.host.should == "64.202.98.91"
        uri.port.should == 554
        uri.path.should == ""
        uri.to_s.should == "rtsp://64.202.98.91:554"
      end
    end
  end
end
