require './lib/rtsp/client'

c = RTSP::Client.new('rtsp://localhost:5554/stream1')

c.options
c.describe
