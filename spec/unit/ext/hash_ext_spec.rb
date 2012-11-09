require 'spec_helper'
require 'ext/hash_ext'

describe Hash do
  describe "#to_headers_s" do
    context "cseq" do
      let(:headers) { { cseq: 123 } }
      specify { headers.to_headers_s.should == "CSeq: 123\r\n" }
    end

    context "a value is a Hash" do
      let(:headers) { { range: { npt: "0.000-" } } }
      specify { headers.to_headers_s.should == "Range: npt=0.000-\r\n" }
    end

    context "a key has underscores" do
      let(:headers) { { if_modified_since: "Sat, 29 Oct 1994 19:43:31 GMT" } }

      it "converts the underscores to hyphens" do
        headers.to_headers_s.should ==
          "If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT\r\n"
      end
    end

    context "many pairs, mixed values" do
      let(:headers) do
        {
          cache_control: ["no-cache", { max_age: 12345 }],
          content_type: ['application/sdp', 'application/x-rtsp-mh']
        }
      end

      specify {
        headers.to_headers_s.should ==
          %Q{Cache-Control: no-cache;max_age=12345\r
Content-Type: application/sdp, application/x-rtsp-mh\r
}
        }
    end
  end
end
