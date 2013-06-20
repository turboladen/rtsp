require 'spec_helper'

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
  it "should have a VERSION constant: version is: #{RTSP::VERSION}" do
    RTSP.const_defined?('VERSION').should be_true
  end
  it "version should be set correctly" do
    if RTSP::VERISON_IS_RELEASE
      RTSP::VERSION.should == '0.4.4'
    elsif RTSP::VERISON_IS_SNAPSHOT
      RTSP::VERSION.should == '0.4.4-SNAPSHOT'
    else
      RTSP::VERSION.should == "0.4.4-#{Time.now.strftime("%Y%m%d-%H%M%S")}"
    end
  end
end
