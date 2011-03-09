Given /^a known RTSP server$/ do
  @server_url = "rtsp://64.202.98.91:554/sa.sdp"
end

When /^I make a "([^"]*)" request$/ do |method|
  @response = RTSP::Request.execute({
      :method => method.to_sym,
      :resource_url => @server_url }
  )
end

When /^I make a "([^"]*)" request with headers:$/ do |method, headers_table|
  # table is a Cucumber::Ast::Table
  headers = {}

  headers_table.hashes.each do |hash|
    header_type = hash["header"].to_sym
    headers[header_type] = hash["value"]
  end

  @response = RTSP::Request.execute({
      :method => method.to_sym,
      :headers => headers,
      :resource_url => @server_url }
  )
end

Then /^I should receive an RTSP response to that OPTIONS request$/ do
  @response.is_a?(RTSP::Response).should be_true
  @response.code.should == 200
  @response.message.should == "OK"
  @response.server.should == "DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )"
  @response.cseq.should == 1
  @response.public.should == "DESCRIBE, SETUP, TEARDOWN, PLAY, PAUSE, OPTIONS, ANNOUNCE, RECORD"
  @response.body.should be_nil
end

Then /^I should receive an RTSP response to that DESCRIBE request$/ do
  @response.is_a?(RTSP::Response).should be_true
  @response.code.should == 200
  @response.message.should == "OK"
  @response.server.should == "DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )"
  @response.cseq.should == 1
  @response.body.is_a?(SDP::Description).should be_true
  @response.body.protocol_version.should == "0"
  @response.body.username.should == "-"
end

Then /^I should receive an RTSP response to that ANNOUNCE request$/ do
  @response.is_a?(RTSP::Response).should be_true
  @response.code.should == 200
  @response.message.should == "OK"
  @response.server.should == "DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )"
  @response.cseq.should == 1
end

Then /^I should receive an RTSP response to that SETUP request$/ do
  @response.is_a?(RTSP::Response).should be_true
  @response.code.should == 200
  @response.message.should == "OK"
  @response.server.should == "DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )"
  @response.cseq.should == 1
  @response.transport.should == ""
end

