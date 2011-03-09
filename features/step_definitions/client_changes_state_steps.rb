Given /^I haven't made any RTSP requests$/ do
  RTSP::Client.configure { |config| config.log = false }
  url = "rtsp://64.202.98.91/sa.sdp"
  @client = RTSP::Client.new url
  @init_state = @client.session_state
end

When /^I issue an "([^"]*)" request$/ do |request_type|
  @client.send request_type.to_sym
end

Then /^the state stays the same$/ do
  pending # express the regexp above with the code you wish you had
end