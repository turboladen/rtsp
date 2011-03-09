Given /^I haven't made any RTSP requests$/ do
  RTSP::Client.configure { |config| config.log = false }
end

When /^I issue an "([^"]*)" request$/ do |request_type|
  raw_response = Kernel.const_get "#{request_type.upcase}_RESPONSE"
  mock_socket = double "MockSocket", :send => "", :recvfrom => [raw_response]

  url = "rtsp://fake-rtsp-server/some_path"
  @client = RTSP::Client.new url, :socket => mock_socket
  @initial_state = @client.session_state

  @client.send request_type.to_sym
end

Then /^the state stays the same$/ do
  @client.session_state.should == @initial_state
end