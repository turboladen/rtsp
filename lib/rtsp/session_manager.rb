require_relative 'logger'


module RTSP
  class SessionManager
    include LogSwitch::Mixin

    def initialize
      @sessions = {}
    end

    def add(new_session)
      RTSP::Logger.log "Adding new session: #{new_session.id}"
      @sessions[new_session.id] = new_session
      new_session.start_cleanup_timer(cleaner)
    end

    def cleaner
      EventMachine.Callback do |session_id|
        RTSP::Logger.log "Deleting session: #{session_id}"
        @sessions.delete session_id
        RTSP::Logger.log "Session list: #{@sessions.keys}"
      end
    end
  end
end
