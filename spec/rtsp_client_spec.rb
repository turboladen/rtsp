require File.dirname(__FILE__) + '/spec_helper.rb'

describe Kernel do
  def self.get_requires
    Dir.chdir File.expand_path(File.dirname(__FILE__) + '/../lib'
    filenames = Dir.glob 'rtsp_client/*.rb'
    requires = filenames.each do |fn|
      fn.chomp!(File.extname(fn))
    end
    return requires
  end

  # Try to require each of the files in RtspClient
  get_requires.each do |r|
    it "should require #{r}" do
      # A require returns true if it was required, false if it had already been
      #   required, and nil if it couldn't require.
      Kernel.require(r.to_s).should_not be_nil
    end
  end
end

describe RtspClient do
  it "should have a VERSION constant" do
    RtspClient.const_defined?('VERSION').should == true
  end

  it "should have a RtspClient_WWW constant" do
    RtspClient.const_defined?('RtspClient_WWW').should == true
  end
end
