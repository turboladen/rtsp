require 'tempfile'
require 'eventmachine'

module RTSP
  class Capturer < EventMachine::Connection

    DEFAULT_CAPFILE_NAME = "rtsp_capture.rtsp"

    attr_reader :capture_file

    def initialize(capture_file=nil)
      @capture_file = capture_file || Tempfile.new(DEFAULT_CAPFILE_NAME)
    end

    def post_init
      puts "client connected"
    end

    def receive_data data
      p data.size
      @capture_file.write data
    end
  end
end