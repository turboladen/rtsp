Feature: Stream from an RTSP server
  As an RTSP consumer
  I want to be able to pull an RTSP stream from a server
  So that I can view its contents
  
  Scenario: Play
    Given an RTSP server at "10.221.222.235" and port 9010
    When I play a stream from that server
    Then I should not receive any errors
    And I should receive data on the same port