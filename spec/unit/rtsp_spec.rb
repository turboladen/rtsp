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
  describe '.release_version?' do
    specify { RTSP.release_version?.should be_false }
  end

  describe '.snapshot_version?' do
    specify { RTSP.snapshot_version?.should be_false }
  end

  describe RTSP::VERSION do
    it 'is set correctly' do
      if RTSP.release_version?
        RTSP::VERSION.should == '0.4.4'
      elsif RTSP.snapshot_version?
        RTSP::VERSION.should == '0.4.4.SNAPSHOT'
      else
        RTSP::VERSION.should match %r[0\.4\.4\.\d{8}\.\d{6}]
      end
    end
  end
end
