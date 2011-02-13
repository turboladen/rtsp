Feature: Client request messages
  As an RTSP client API user
  I want to make RTSP requests
  So that I can build a client using these request messages

  Scenario: OPTIONS
    Given a known RTSP server
    When I make a "options" request
    Then I should receive an RTSP response to that OPTIONS request