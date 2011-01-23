Feature: Stream from an RTSP server
  As an RTSP consumer
  I want to be able to pull an RTSP stream from a server
  So that I can view its contents
  
  @wip
  Scenario: Play
    Given an RTSP server at "10.221.222.235" and port 9010 and URL ""
    When I play a stream from that server
    Then I should not receive any errors
    And I should receive data on the same port

  Scenario: Describe
    Given I know what the describe response looks like
    When I ask the server to describe
    Then I should not receive any errors
    And I should receive data on the same port
