require './lib/rtsp/client'

#RTSP::Logger.log = false
RTSP::Logger.log = true

cap_file = File.new("soma_cap.rtsp", "wb")
url = "rtsp://64.202.98.91/sa.sdp"
client = RTSP::Client.new(url)

client.capturer.rtp_file = cap_file
# client = RTSP::Client.new(url) do |client, capturer|
#   description = SDP.parse(open("http://test/description.sdp"))
#   client.timeout = 30
#   client.socket = TCPSocket.new
#   client.interleave = true
#   capturer.file = Tempfile.new "test"
#   capturer.capture_port = 8555
#   capturer.protocol = :tcp
# end

client.options
client.describe

media_track = client.media_control_tracks.first
puts "media track: #{media_track}"

aggregate_track = client.aggregate_control_track
puts "aggregate track: #{aggregate_track}"

client.setup media_track
#client.setup media_track, :transport => "RTP/AVP;unicast;client_port=9000-9001"
#client.setup media_track, :transport => "RTP/AVP/TCP;unicast;interleaved=0-1"
#client[media_track].setup
#client.media_control_tracks.play
client.play aggregate_track
sleep 15
#client[aggregate_track].play
client.teardown aggregate_track



