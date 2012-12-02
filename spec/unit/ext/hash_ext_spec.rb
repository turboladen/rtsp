require 'spec_helper'
require 'ext/hash_ext'

describe Hash do
  describe "#assemble_headers" do
    pending
  end

  describe "#transport_to_s" do
    pending
  end

  describe "#session_to_s" do
    context "with timeout" do
      let(:session_hash) { { session_id: 1234, timeout: 5678 } }
      specify {
        subject.send(:session_values_to_s, session_hash).should ==
          "1234;timeout=5678"
      }
    end

    context "no timeout" do
      let(:session_hash) { { session_id: 1234 } }
      specify {
        subject.send(:session_values_to_s, session_hash).should == "1234"
      }
    end
  end

  describe "#order_headers" do
    pending
  end

  describe "#basic_header_values_to_s" do
    context "param is a Hash" do
      context "header field is a Symbol" do
        context "single key/value pair" do
          let(:values) { { field: "value" } }

          specify {
            subject.send(:basic_header_values_to_s, values).should ==
              "field=value"
          }
        end

        context "two key/value pairs" do
          let(:values) { { f1: "v1", f2: "v2" } }

          specify {
            subject.send(:basic_header_values_to_s, values).should ==
              "f1=v1;f2=v2"
          }
        end
      end
    end

    context "param is a Array" do
      context "header field is a Hash" do
        pending "Not sure why this conditional is in the method..."

        let(:values) { [{ field: { f1: "v1" } }] }

        it "calls the same method again but on the field" do
          subject.send(:basic_header_values_to_s, values).should ==
            "field="
        end
      end
    end
  end
end
