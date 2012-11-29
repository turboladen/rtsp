require 'spec_helper'
require 'rtsp/response'

describe RTSP::Response do
  describe ".parse" do
    it "expects a non-nil string on" do
      expect { RTSP::Response.parse(nil) }.to raise_exception RTSP::Error
    end

    it "expects a non-empty string on" do
      expect { RTSP::Response.parse("") }.to raise_exception RTSP::Error
    end
  end

  describe "#extract_status_line" do
    subject { RTSP::Response.new " " }

    context "RTSP response" do
      let(:status_line) { "RTSP/1.0 200 OK\r\n" }
      before { subject.extract_status_line(status_line) }

      specify {
        subject.rtsp_version.should == "1.0"
        subject.code.should == 200
        subject.status_message.should == "OK"
      }
    end

    context "HTTP response" do
      let(:status_line) { "HTTP/1.1 200 OK\r\n" }
      before { subject.extract_status_line(status_line) }

      specify {
        subject.rtsp_version.should == "1.1"
        subject.code.should == 200
        subject.status_message.should == "OK"
      }
    end
  end
end
