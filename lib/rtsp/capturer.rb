require 'eventmachine'

module RTSP
  class Capturer < EventMachine::Connection

    DEFAULT_CAPFILE_NAME = "rtsp_capture.rtsp"

    attr_reader :capture_file

    def post_init
      puts "client connected"
    end

    def receive_data data
      p data
    end
  end
end