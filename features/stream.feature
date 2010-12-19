Feature: Stream from an RTSP server
  As an RTSP consumer
  I want to be able to pull an RTSP stream from a server
  So that I can view its contents
  
  Scenario: Play
    Given an RTSP server at "10.221.222.235" and port 9010 and URL ""
    When I play a stream from that server
    Then I should not receive any errors
    And I should receive data on the same port

  Scenario: Describe
    Given an RTSP server at "64.202.98.91" and port 554 and URL "/gs.sdp"
    When I ask the server to describe
    Then I should not receive any errors
    And I should receive data on the same port
