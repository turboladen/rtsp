require 'logger'

class Logger
  def format_message(level, time, progname, msg)
    "[#{time}] #{msg.to_s}\n"
  end
end