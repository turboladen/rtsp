require 'pathname'

#  Document me!
module RtspClient
  VERSION = '0.0.1'
  _WWW = 'http://confluence.pelco.org/wiki/display/syssoft/'
  LIBRARY_ROOT = File.dirname(__FILE__)
  PROJECT_ROOT = Pathname.new(LIBRARY_ROOT).parent
end
