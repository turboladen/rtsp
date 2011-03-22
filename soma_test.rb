require './lib/rtsp/client'

#RTSP::Client.log = false

url = "rtsp://64.202.98.91/sa.sdp"
client = RTSP::Client.new url

client.options
client.describe

media_track = client.media_control_tracks.first
puts "media track: #{media_track}"

aggregate_track = client.aggregate_control_track
puts "aggregate track: #{aggregate_track}"

client.setup media_track
#client.setup media_track, :transport => "RTP/AVP;unicast;client_port=9000-9001"
#client[media_track].setup
#client.media_control_tracks.play
client.play aggregate_track
#client[aggregate_track].play
client.teardown aggregate_track
