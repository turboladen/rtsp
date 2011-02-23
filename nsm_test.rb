require './lib/rtsp/client'

url = "rtsp://10.221.222.210/?deviceid=uuid:100330fe-5d3e-4a5e-98c7-0000a6504b8c-Camera-1"
r = RTSP::Client.new url

r.options
r.describe

media_track = r.media_control_tracks.first
puts "media track: #{media_track}"

aggregate_track = r.aggregate_control_track
puts "aggregate track: #{aggregate_track}"

r.setup media_track
r.play aggregate_track

