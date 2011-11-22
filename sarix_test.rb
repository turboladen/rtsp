require './lib/rtsp/client'

cap_file = File.new("sarix_cap.rtsp", "wb")
url = "rtsp://10.221.222.242/stream1"
r = RTSP::Client.new url
r.capturer.rtp_file = cap_file

r.options
r.describe

media_track = r.media_control_tracks.first
puts "media track: #{media_track}"

aggregate_track = r.aggregate_control_track
puts "aggregate track: #{aggregate_track}"

r.setup media_track
r.play aggregate_track

sleep 15

r.teardown media_track

