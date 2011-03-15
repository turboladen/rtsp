Given /^I haven't made any RTSP requests$/ do
  RTSP::Client.configure { |config| config.log = false }
end

Given /^I have set up a stream$/ do
  @url = "rtsp://fake-rtsp-server/some_path"
  @client = RTSP::Client.new @url, :socket => @fake_server
  @client.setup @url
  @client.session_state.should == :ready
end

Given /^I have started playing a stream$/ do
  @client.play @url
  @client.session_state.should == :playing
end

When /^I issue an "([^"]*)" request with "([^"]*)"$/ do |request_type, params|
  unless @client
    url = "rtsp://fake-rtsp-server/some_path"
    @client = RTSP::Client.new url, :socket => @fake_server
  end

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