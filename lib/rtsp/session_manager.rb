require_relative 'logger'


module RTSP
  class SessionManager < Hash
    include LogSwitch::Mixin

    def add(new_session)
      RTSP::Logger.log "Adding new session: #{new_session.id}"
      self[new_session.id] = new_session
      new_session.start_cleanup_timer(cleaner)
    end

    def cleaner
      EventMachine.Callback do |session_id|
        RTSP::Logger.log "Deleting session: #{session_id}"
        self.delete session_id
        RTSP::Logger.log "Session list: #{keys}"
      end
    end
  end
end
