require_relative '../ext/logger'

module RTSP
  module Global
    DEFAULT_RTSP_PORT = 554
    DEFAULT_VERSION = '1.0'

    # Sets whether to log RTSP requests & responses.
    attr_writer :log

    # @return [Boolean] true if logging is enabled; false if it's turned off.
    def log?
      @log != false
    end

    # Sets the type logger to use.
    attr_writer :logger

    # By default, this creates a standard Ruby Logger.  If a different type was
    # passed in via +#logger=+, this returns that object.
    #
    # @return [Logger]
    def logger
      @logger ||= ::Logger.new STDOUT
    end

    # @return [Symbol] The Logger method to use for logging all messages.
    attr_writer :log_level

    # The Logger method to use for logging all messages.
    #
    # @return [Symbol] Defaults to +:debug+.
    def log_level
      @log_level ||= :debug
    end

    # @param [String] message The string to log.
    def log(message, level=log_level)
      logger.send(level, message) if log?
    end

    # Use to disable the raising of +RTSP::Error+s.
    attr_writer :raise_errors

    # @return [Boolean] true if set to raise errors; false if not.
    def raise_errors?
      @raise_errors != false
    end

    # @return [String] The RTSP version.
    def rtsp_version
      @version ||= DEFAULT_VERSION
    end

    # Resets class variables back to defaults.
    def reset_config!
      self.log = true
      self.logger = ::Logger.new STDOUT
      self.log_level = :debug
      self.raise_errors = true
    end
  end
end
