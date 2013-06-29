require 'pathname'
require_relative 'rtsp/version'

# This base module simply defines properties about the library.  See child
# classes/modules for the meat.
module RTSP
  def self.release_version?
    !!RELEASE
  end

  def self.snapshot_version?
    !!SNAPSHOT
  end
end
