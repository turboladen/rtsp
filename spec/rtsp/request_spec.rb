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