require 'logger'

# TODO: Move to ext/logger.rb
class Logger
  def format_message(level, time, progname, msg)
    "[#{time}] #{msg.to_s}\n"
  end
end

module RTSP
  module Global
    DEFAULT_PORT = 554
    DEFAULT_VERSION = '1.0'

    # Sets whether to log RTSP requests & responses.
    attr_writer :log

    def log?
      @log != false
    end

    # Sets the logger to use.
    attr_writer :logger

    def logger
      @logger ||= ::Logger.new STDOUT
    end

    attr_writer :log_level

    def log_level
      @log_level ||= :debug
    end

    def log(message)
      logger.send(log_level, message) if log?
    end

    def raise_errors?
      @raise_errors != false
    end

    attr_writer :rtsp_version

    def rtsp_version
      @version ||= DEFAULT_VERSION
    end
  end
end