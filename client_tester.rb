#!/usr/bin/env ruby

require 'thor'
require './lib/rtsp/client'
require 'bundler/setup'

RTSP::Client.log = true

class ClientTester < Thor
  include Thor::Actions

  desc "soma", "Pulls a stream from SomaFM"
  def soma
    url = "rtsp://64.202.98.91/sa.sdp"
    pull_stream url
  end

  desc "sarix", "Pulls a stream from a Sarix camera"
  def sarix
    url = "rtsp://10.221.222.242/stream1"
    pull_stream url
  end

  desc "nsm", "Pulls a stream from a NSM"
  def nsm
    url = "rtsp://10.221.222.12/?deviceid=uuid:0ed8f1e9-0ce2-987c-4649-db3ae7aa3a04"
    pull_stream url
  end

  no_tasks do
    def pull_stream(url)
      #cap_file = File.new("soma_cap.rtsp", "wb")
      url = "rtsp://64.202.98.91/sa.sdp"
      client = RTSP::Client.new(url)

      #client.capturer.rtp_file = cap_file
      # client = RTSP::Client.new(url) do |client, capturer|
      #   description = SDP.parse(open("http://test/description.sdp"))
      #   client.timeout = 30
      #   client.socket = TCPSocket.new
      #   client.interleave = true
      #   capturer.file = Tempfile.new "test"
      #   capturer.capture_port = 8555
      #   capturer.protocol = :tcp
      # end

      client.options
      client.describe

      media_track = client.media_control_tracks.first
      puts "media track: #{media_track}"

      aggregate_track = client.aggregate_control_track
      puts "aggregate track: #{aggregate_track}"

      client.setup media_track
      #client.setup media_track, :transport => "RTP/AVP;unicast;client_port=9000-9001"
      #client.setup media_track, :transport => "RTP/AVP/TCP;unicast;interleaved=0-1"
      #client[media_track].setup
      #client.media_control_tracks.play
      #client.play(aggregate_track)
      client.play(aggregate_track) do |packet|
        this_packet = packet.sequence_number
        puts "RTP sequence: #{this_packet}"

        if defined? last_packet
          puts "last: #{last_packet}"
          diff = this_packet - last_packet
          if diff != 1
            puts "ZOMG!!!!!!!! PACKET DIFF: #{diff}"
          end
        end

        last_packet = packet.sequence_number
      end

      sleep 1
      #client[aggregate_track].play
      client.teardown aggregate_track
      p client.capturer.capture_file.path
      p client.capturer.capture_file.size
    end
  end
end

ClientTester.start
