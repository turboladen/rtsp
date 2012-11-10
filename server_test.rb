require './lib/rtsp/server'

server = RTSP::Server.new('localhost', 5554)

server.stream_list = {
  'rtsp://localhost:5554/stream1' => RTSP::Stream.new
}

server.start
