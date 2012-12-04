class Time
  def to_ntp
    # To convert Unix time to NTP time, add this.
    ntp_to_unix_time_diff = 2208988800
    self.to_i + ntp_to_unix_time_diff
  end
end
