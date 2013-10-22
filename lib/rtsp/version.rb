module RTSP
  SNAPSHOT = false
  RELEASE = true
  BASE_VERSION = '0.4.5'

  VERSION = if RELEASE
              BASE_VERSION
            elsif SNAPSHOT
              "#{BASE_VERSION}.SNAPSHOT"
            else
              "#{BASE_VERSION}.#{Time.now.strftime('%Y%m%d.%H%M%S')}"
            end
end
