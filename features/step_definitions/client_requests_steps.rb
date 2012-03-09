Given /^a known RTSP server$/ do
  @server_url = "rtsp://64.202.98.91:554/sa.sdp"

  @client = RTSP::Client.new(@server_url) do |connection|
    connection.socket = @fake_server
    connection.timeout = 3
  end
end

When /^I make a "([^"]*)" request$/ do |method|
  @response = if method == 'announce'
    @client.setup(@server_url)
    @client.announce(@server_url, @client.describe)
  else
    @client.send(method.to_sym)
  end
end

When /^I make a "([^"]*)" request with headers:$/ do |method, headers_table|
  # table is a Cucumber::Ast::Table
  headers = {}

  headers_table.hashes.each do |hash|
    header_type = hash["header"].to_sym
    headers[header_type] = hash["value"]
  end

  @response = if method == 'setup'
    @client.setup(@server_url, headers)
  else
    @client.send(method.to_sym, headers)
  end
end

Then /^I should receive an RTSP response to that OPTIONS request$/ do
  @response.should be_a RTSP::Response
  @response.code.should == 200
  @response.message.should == "OK"
  @response.cseq.should == 1
  @response.public.should == "DESCRIBE, SETUP, TEARDOWN, PLAY, PAUSE"
  @response.body.should be_empty
end

Then /^I should receive an RTSP response to that DESCRIBE request$/ do
  @response.should be_a RTSP::Response
  @response.code.should == 200
  @response.message.should == "OK"
  @response.server.should == "DSS/5.5 (Build/489.7; Platform/Linux; Release/Darwin; )"
  @response.cseq.should == 1
  @response.body.should be_a SDP::Description
  @response.body.username.should == "-"
end

Then /^I should receive an RTSP response to that ANNOUNCE request$/ do
  @response.should be_a RTSP::Response
  @response.code.should == 200
  @response.message.should == "OK"
  @response.cseq.should == 2
end

Then /^I should receive an RTSP response to that SETUP request$/ do
  @response.should be_a RTSP::Response
  @response.code.should == 200
  @response.message.should == "OK"
  @response.cseq.should == 1
  @response.transport.should match(/RTP\/AVP;unicast;destination=\S+;source=\S+;client_port=\d+-\d+;server_port=\d+-\d+/)
end

