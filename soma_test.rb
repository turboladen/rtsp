require './lib/rtsp/client'

url = "rtsp://64.202.98.91/sa.sdp"
r = RTSP::Client.new url

r.options
r.describe

media_track = r.media_control_tracks.first
puts "media track: #{media_track}"

aggregate_track = r.aggregate_control_track
puts "aggregate track: #{aggregate_track}"

r.setup media_track
r.play aggregate_track
r.teardown aggregate_track
