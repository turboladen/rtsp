require 'log_switch'

module RTSP
  class Logger
    extend LogSwitch
  end
end

RTSP::Logger.log_class_name = true
RTSP::Logger.log = false
