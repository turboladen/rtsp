require File.dirname(__FILE__) + '/../spec_helper'
require 'rtsp/request'

describe RTSP::Request do
  before do
    @stream = "rtsp://1.2.3.4/stream1"
    @mock_socket = double 'MockSocket'
  end

  def build_request_with headers
    RTSP::Request.new({ :method => :options,
        :resource_url => "http://localhost",
        :socket => @mock_socket,
        :headers => headers })
  end

  context "#initialize" do
    it "raises when no :method is passed in" do
      lambda {
        RTSP::Request.new({ :resource_url => @stream })
        }.should raise_error ArgumentError
    end

    it "raises when no :resource_url is passed in" do
      lambda {
        RTSP::Request.new({ :method => :options })
      }.should raise_error ArgumentError
    end

    context "parses the resource URL to a URI" do
      it "with scheme, IP, port, and path" do
        request = RTSP::Request.new( { :method => :options,
            :resource_url => "rtsp://64.202.98.91:554/sa.sdp",
            :socket => @mock_socket
        })
        request.resource_uri.scheme.should == "rtsp"
        request.resource_uri.host.should == "64.202.98.91"
        request.resource_uri.port.should == 554
        request.resource_uri.path.should == "/sa.sdp"
      end

      it "with scheme, IP, path; port defaults to 554" do
        pending "decision on whether to add 554 in to the URL or not"
        request = RTSP::Request.new( { :method => :options,
            :resource_url => "rtsp://64.202.98.91/sa.sdp",
            :socket => @mock_socket
        })
        request.resource_uri.scheme.should == "rtsp"
        request.resource_uri.host.should == "64.202.98.91"
        request.resource_uri.port.should == 554
        request.resource_uri.path.should == "/sa.sdp"
      end

      it "with IP, path; port defaults to 554; scheme defaults to 'rtsp'" do
        request = RTSP::Request.new( { :method => :options,
            :resource_url => "rtsp://64.202.98.91/sa.sdp",
            :socket => @mock_socket
        })
        request.resource_uri.scheme.should == "rtsp"
        request.resource_uri.host.should == "64.202.98.91"
        #request.resource_uri.port.should == 554
        request.resource_uri.path.should == "/sa.sdp"
      end

      it "with scheme, IP, port" do
        request = RTSP::Request.new( { :method => :options,
            :resource_url => "rtsp://64.202.98.91:554",
            :socket => @mock_socket
        })
        request.resource_uri.scheme.should == "rtsp"
        request.resource_uri.host.should == "64.202.98.91"
        #request.resource_uri.port.should == 554
        request.resource_uri.path.should == ""
      end
    end
  end

  context "#headers_to_s turns a Hash into an String of header strings" do
    it "single header, non-hyphenated name, hash value" do
      header = { :range => { :npt => "0.000-" } }
      request = build_request_with header

      string = request.headers_to_s(header)
      string.is_a?(String).should be_true
      string.should include "Range: npt=0.000-"
    end

    it "single header, hyphenated, non-hash value" do
      header = { :if_modified_since => "Sat, 29 Oct 1994 19:43:31 GMT" }
      request = build_request_with header

      string = request.headers_to_s(header)
      string.is_a?(String).should be_true
      string.should include "If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT"
    end

    it "two headers, mixed hyphenated, array & hash values" do
      headers = {
        :cache_control => ["no-cache", { :max_age => 12345 }],
        :content_type => ['application/sdp', 'application/x-rtsp-mh']
      }
      request = build_request_with headers

      string = request.headers_to_s(headers)
      string.is_a?(String).should be_true
      string.should include "Cache-Control: no-cache;max_age=12345"
      string.should include "Content-Type: application/sdp, application/x-rtsp-mh"
    end
  end
end