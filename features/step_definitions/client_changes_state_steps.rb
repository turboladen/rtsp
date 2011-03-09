Given /^I haven't made any RTSP requests$/ do
  RTSP::Client.configure { |config| config.log = false }
end

Given /^I have set up a stream$/ do
  mock_socket = double "MockSocket", :send => "", :recvfrom => [SETUP_RESPONSE]

  url = "rtsp://fake-rtsp-server/some_path"
  @client = RTSP::Client.new url, :socket => mock_socket

  @client.setup url
end

When /^I issue an "([^"]*)" request with "([^"]*)"$/ do |request_type, params|
  raw_response = Kernel.const_get "#{request_type.upcase}_RESPONSE"
  mock_socket = double "MockSocket", :send => "", :recvfrom => [raw_response]

  url = "rtsp://fake-rtsp-server/some_path"
  @client = RTSP::Client.new url, :socket => mock_socket
  @initial_state = @client.session_state
  params = params.empty? ? {} : params

  @client.send(request_type.to_sym, params)
end

Then /^the state stays the same$/ do
  @client.session_state.should == @initial_state
end

Then /^the state changes to "([^"]*)"$/ do |new_state|
  @client.session_state.should == new_state.to_sym
end