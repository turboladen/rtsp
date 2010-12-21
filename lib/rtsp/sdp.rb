require 'uri'

class SDP

  # Ignore any attributes types that aren't in this list.
  TYPE = { :session => [:v, :o, :s, :i, :u, :e, :p, :c, :b, :z, :k, :a],
    :time => [:t, :r],
    :media => [:m, :i, :c, :b, :k, :a]
  }

  def self.parse_sdp sdp_text
    sdp = {}
    sdp_text =~ /^v=(.*)/i
    sdp[:version] = Integer $1

    sdp[:origin] = {}
    sdp_text =~ /^o=(.*)/i
    origin_params = $1.split(" ")
    sdp[:origin][:username]         = origin_params[0]
    sdp[:origin][:session_id]       = origin_params[1]
    sdp[:origin][:session_version]  = origin_params[2].to_i # Should be NTP timestamp
    sdp[:origin][:net_type]         = origin_params[3]
    sdp[:origin][:addr_type]        = origin_params[4]
    sdp[:origin][:unicast_address]  = origin_params[5]

    sdp_text =~ /^s=(.*)/
    sdp[:session_name] = $1

    sdp_text =~ /^i=(.*)/
    sdp[:session_information] = $1

    found_text = false
    found_text = sdp_text =~ /^u=(.*)/
    if found_text
      sdp[:uri] = $1
    end

    #sdp_text =~ /^u=(.*)/i
    #description_uri = URI.parse $1

    #sdp_text =~ /^k=(.*)/i
    #encryption_key = URI.parse $1

    #sdp_text =~ /^a=(.*)/i
    #attributes
    #  = URI.parse $1

    sdp
  end

  def initialize sdp_text
    @version
    @originator
    @session_name
    @media = {}
    @media[:name] = ""
    @media[:transport_address]
  end
end