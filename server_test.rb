require './lib/rtsp/server'
require './lib/rtsp/application'

=begin
server = RTSP::Server.new('localhost', 5554)

server.stream_list = {
  'rtsp://localhost:5554/stream1' => RTSP::Stream.new
}

server.start
=end

class MyServer < RTSP::Application
  stream '/stream1' do |stream|
    stream.type = :socat
    stream.source = 'rtsp://239.221.222.241:6780'

    stream.codec = :h264
=begin
    stream.description.media = :video
    stream.description.port = 6770
    stream.description.format = 96
    stream.description.protocol = "RTP/AVP"
    stream.description.attributes << "fmtp:96 profile-level-id=5;" +
      "config=000001b005000001b509000001000000012000c888ba9860fa22c087828307"

    stream.description.attributes << "rtpmap:96 H264/90000"
=end
  end
end

MyServer.run!


=begin
class SocatStreamer
  def play
    #
  end

  def pause
    #
  end
end

server = RTSP::Server.start('localhost', 5554) do
  presentation do |p|
    p.track_uri = "trackID=1"
  end

  player = play_block
end
=end



