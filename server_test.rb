require './lib/rtsp/server'
require './lib/rtsp/application'


RTSP::Logger.log = true


class MyServer < RTSP::Application
  stream '/stream1' do |stream|
    stream.source = 'udp://127.0.0.1:1234'
    stream.codec = :h264

=begin
    stream.ip_addressing_type :multicast
    stream.destination_port 6770
    stream.destination_protocol "UDP"
=end

    stream.destination.ip_addressing_type = :multicast
    stream.destination.protocol = :UDP
  end

  stream '/stream2' do |stream|
    stream.type = :socat
    stream.source = 'udp://239.221.222.241:6780'

    stream.codec = :h264
=begin
    stream.ip_addressing_type :unicast
    stream.destination_port 6780
    stream.destination_protocol "TCP"
=end
    stream.destination.ip_addressing_type = :unicast
    stream.destination.protocol = :TCP
    stream.destination.start_port = 7890
  end

  #stream '/stream3' do |stream|
  #  stream.source "/Users/Steveloveless/Music/iTunes/iTunes Media/Movies/Burning HQ/Burning HQ.m4v"
  #end
end

MyServer.run!
