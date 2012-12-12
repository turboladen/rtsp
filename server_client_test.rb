require './lib/rtsp/client'

RTSP::Logger.log = true

c = RTSP::Client.new('rtsp://localhost:5554/test')

c.options
c.describe

