require './lib/rtsp/server'
require './lib/rtsp/application'


RTSP::Logger.log = true


class MyServer < RTSP::Application
  stream '/stream1' do |stream|
    stream.type :socat
    stream.source 'rtsp://239.221.222.241:6780'

    stream.codec :h264
    stream.ip_addressing_type :unicast
    stream.destination_port 6770
    stream.transport_protocol "RTP/AVP"
    stream.lower_transport "TCP"
  end

  stream '/stream2' do |stream|
    stream.type :socat
    stream.source 'rtsp://239.221.222.241:6780'

    stream.codec :h264
    stream.ip_addressing_type :multicast
    stream.destination_port 6780
    stream.transport_protocol "RTP/AVP"
    stream.lower_transport "UDP"
  end
end

MyServer.run!
