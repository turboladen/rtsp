Feature: Get SDP file fields and marshall into Ruby data types
  As an RTSP consumer
  I want to be able to be able to read SDP files into Ruby data types
  So that it's easy to determine how to work with the RTSP stream
  
  Scenario: Parse the RFC 4566 example
    Given the RFC 4566 SDP example in a file
    When I parse the file
    Then the <value> for <field> is accessible via <rubyfied>
      | field | rubyfied            | value                       |
      | v     | :version             | 0                           |
      | o[0]  | [:origin][:username]   | "jdoe"                      |
      | o[1]  | origin[:session_id] | 2890844526                  |
      | o[2]  | origin[:session_version] | 2890842807             |
      | o[3]  | origin[:net_type]   | "IN"                        |
      | o[4]  | origin[:address_type] | "IP4"                     |
      | o[5]  | origin[:unicast_address] | "10.47.16.5"           |
      | s     | session_name        | "SDP Seminar"               |
      | i     | session_information | "A Seminar on the session description protocol" |
      | u     | uri     | "http://www.example.com/seminars/sdp.pdf" |
      | e     | email_address       | j.doe@example.com (Jane Doe) |
      | c[0]  | connection_data[:net_type]      | "IN"            |
      | c[1]  | connection_data[:address_type]  | "IP4"           |
      | c[2]  | connection_data[:connection_address] | "224.2.17.12/127" |
      | t[0]  | timing[:start_time]         | 2873397496          |
      | t[1]  | timing[:stop_time]          | 2873404696          |
      | a[0]  | attribute[:recvonly]        | true                |
      | m[0][1] | media[:audio][:port]      | 49170               |
      | m[0][2] | media[:audio][:protocol]  | "RTP/AVP"           |
      | m[0][3] | media[:audio][:format]    | 0                   |
      | m[1][1] | media[:video][:port]      | 51372               |
      | m[1][2] | media[:video][:protocol]  | "RTP/AVP"           |
      | m[1][3] | media[:video][:format]    | 99                  |
      | a[1][1] | attribute[:rtpmap][:payload_type]   | 99        |
      | a[1][2] | attribute[:rtpmap][:encoding_name]  | "h263-1998" |
      | a[1][3] | attribute[:rtpmap][:clock_rate]     | 90000     |
      
