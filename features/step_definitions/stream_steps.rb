Given /^an RTSP server at "([^"]*)"$/ do |ip_address|
  @client = RTSPClient.new( { :host => ip_address })
  @client.setup
end

When /^I play a stream from that server$/ do
  @play_result = lambda { @client.play }
end

Then /^I should not receive any errors$/ do
  @play_result.should_not raise_error
end

Then /^I should receive data on port (\d+)$/ do |rtp_port|
  socket = UDPSocket.new
  socket.bind("0.0.0.0", rtp_port)

  data = socket.recvfrom(102400)[0]
=begin
  while data = socket.recvfrom(102400)[0]
    b2 = data[1]
    if data[1] & 0b1000_0000 == 1 #0x80
      pt = (0b0111_1111) & b2 #0x7F
      sq = (data[2]<<8) | data[3]
      ts = ((data[4]<<24) | (data[5]<<16) | (data[6]<<8) | (data[7]))
      ssrc = ((data[8]<<24) | (data[9]<<16) | (data[10]<<8) | (data[11]))
      puts "marker size:#{data.size} type:#{pt} sq:#{sq} ts:#{ts} ssrc:#{ssrc}"
    end
  end
=end

  socket.close
  data.should_not be_nil
end