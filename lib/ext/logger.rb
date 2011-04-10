require 'logger'

class Logger
  # Redefining to output a smaller timestamp.
  def format_message(level, time, progname, msg)
    "[#{time}] #{msg.to_s}\n"
  end
end
