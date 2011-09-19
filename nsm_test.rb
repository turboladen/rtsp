require './lib/rtsp/client'

#url = "rtsp://10.221.222.210/?deviceid=uuid:100330fe-5d3e-4a5e-98c7-0000a6504b8c-Camera-1"
url = "rtsp://10.221.222.12/?deviceid=uuid:0ed8f1e9-0ce2-987c-4649-db3ae7aa3a04"

cap_file = File.new("nsm_cap.rtsp", "wb")
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
sleep 2
r.pause aggregate_track
sleep 2
r.play aggregate_track
sleep 2
r.teardown aggregate_track
