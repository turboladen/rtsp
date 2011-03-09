Given /^I haven't made any RTSP requests$/ do
  RTSP::Client.configure { |config| config.log = false }
end

When /^I issue an "([^"]*)" request$/ do |request_type|
  mock_socket = double "MockSocket", :send => "", :recvfrom => [OPTIONS_RESPONSE]

  url = "rtsp://fake-rtsp-server/some_path"
  @client = RTSP::Client.new url, :socket => mock_socket
  @initial_state = @client.session_state

  @client.send request_type.to_sym
end

Then /^the state stays the same$/ do
  @client.session_state.should == @initial_state
end