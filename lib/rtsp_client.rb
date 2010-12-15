require 'pathname'

#  Document me!
module RTSPClient
  VERSION = '0.0.1'
  WWW = 'http://github.com/turboladen/rtsp_client'
  LIBRARY_ROOT = File.dirname(__FILE__)
  PROJECT_ROOT = Pathname.new(LIBRARY_ROOT).parent
end
