Feature: Get SDP file fields and marshall into Ruby data types
  As an RTSP consumer
  I want to be able to be able to read SDP files into Ruby data types
  So that it's easy to determine how to work with the RTSP stream
  
  Scenario: SDP file using all possible spec'ed SDP fields
    Given an SDP file that contains all possible spec'ed SDP fields
    When I create an SDP object from the file
    Then all fields and values are represented as Hashes
