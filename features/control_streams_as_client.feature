Feature: Control stream from an RTSP server
  As an RTSP consumer
  I want to be able to control RTSP streams from a server
  So that I can view its contents as I desire

  @wip
  Scenario: Play single stream
    Given an RTSP server at "10.221.222.235" and port 9010 and URL ""
    When I play a stream from that server
    Then I should not receive any errors
    And I should receive data on the same port

  Scenario: Play then pause single stream
    Given an RTSP server at "10.221.222.235" and port 9010 and URL ""
    When I play a stream from that server for 10 seconds
    And I pause that stream
    Then I should not receive data on the same port

  Scenario: Play two streams individually and simultaneously

  Scenario: Play then pause two streams individually and simultaneously

  Scenario: Play two streams using the aggregate control URL

  Scenario: Play then pause two streams using the aggregate control URL

