Given /^an RTSP server at "([^"]*)" and port (\d+)$/ do |ip_address, port|
  @rtp_port = port.to_i
  @client = RTSP::Client.new(ip_address) do |connection, capturer|
    capturer.rtp_port = @rtp_port
  end
end

Given /^an RTSP server at "([^"]*)" and port (\d+) and URL "([^"]*)"$/ do |ip_address, port, path|
  uri = "rtsp://#{ip_address}:#{port}#{path}"
  @rtp_port = port
  @client = RTSP::Client.new(uri) do |connection, capturer|
    capturer.rtp_port = @rtp_port
  end
end

When /^I play a stream from that server$/ do
  @play_result = lambda { @client.play }
end

Then /^I should not receive any errors$/ do
  @play_result.should_not raise_error
end

Then /^I should receive data on the same port$/ do
  @client.capturer.rtp_file.should_not be_empty
end

Given /^I know what the describe response looks like$/ do
  @response_text = @fake_server.describe
end

When /^I ask the server to describe$/ do
  puts @client.describe
end
