require_relative 'spec_helper'

describe Kernel do
  def self.get_requires
    Dir[File.dirname(__FILE__) + '/../lib/**/*.rb']
  end

  # Try to require each of the files in RTSP
  get_requires.each do |r|
    it "should require #{r}" do

      # A require returns true if it was required, false if it had already been
      # required, and nil if it couldn't require.
      Kernel.require(r.to_s).should_not be_nil
    end
  end
end

describe RTSP do
  it "should have a VERSION constant" do
    RTSP.const_defined?('VERSION').should be_true
  end

  it "has version 0.2.2" do
    RTSP::VERSION.should == '0.2.2'
  end
end
