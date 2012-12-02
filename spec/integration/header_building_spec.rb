require 'spec_helper'
require 'ext/hash_ext'

describe "Header building" do
  let(:headers) do
    {
      cseq: 123,
      range: {
        npt: "0.000-"
      },
      if_modified_since: "Sat, 29 Oct 1994 19:43:31 GMT",
      cache_control: ["no-cache", { max_age: 12345 }],
      content_type: %w[application/sdp application/x-rtsp-mh]
    }
  end

  specify {
    headers.to_headers_s.should == <<-HEADERS
CSeq: 123\r
Range: npt=0.000-\r
If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT\r
Cache-Control: no-cache;max-age=12345\r
Content-Type: application/sdp;
    HEADERS
  }

end
