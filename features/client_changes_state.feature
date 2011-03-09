Feature: Client changes state
  As an RTSP client user
  I want to monitor the state of my client
  So that I can be sure of what my client is doing at any time

  Scenario: State doesn't change after OPTIONS
    Given I haven't made any RTSP requests
    When I issue an "options" request
    Then the state stays the same