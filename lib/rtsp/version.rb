module RTSP
  # rtsp version
  VERISON_IS_SNAPSHOT = false
  VERISON_IS_RELEASE = false
  version = "0.4.4"
  snap_str =   "#{version}-SNAPSHOT"
  daily_str  =  "#{version}-#{Time.now.strftime("%Y%m%d-%H%M%S")}"
  VERSION = (VERISON_IS_RELEASE) ? version : ((VERISON_IS_SNAPSHOT) ? snap_str : daily_str )
end
