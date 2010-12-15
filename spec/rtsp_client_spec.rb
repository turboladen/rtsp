require File.dirname(__FILE__) + '/spec_helper.rb'

describe Kernel do
  def self.get_requires
    Dir[File.dirname(__FILE__) + '/../lib/**/*.rb']
  end

  # Try to require each of the files in RTSPClient
  get_requires.each do |r|
    it "should require #{r}" do

      # A require returns true if it was required, false if it had already been
      # required, and nil if it couldn't require.
      Kernel.require(r.to_s).should_not be_nil
    end
  end
end

describe RTSPClient do
  it "should have a VERSION constant" do
    RTSPClient.const_defined?('VERSION').should be_true
  end

  it "should have a WWW constant" do
    RTSPClient.const_defined?('WWW').should be_true
  end
end
