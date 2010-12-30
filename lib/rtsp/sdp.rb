require 'etc'
require 'net/ntp'

class SDP < Hash
  SDP_VERSION = 0

  SDP_TYPE = {
    :version => /^v=(.*)/,
    :origin => /^o=(.*)/,
    :session_name => /^s=(.*)/,
    :session_information => /^i=(.*)/,
    :uri => /^u=(.*)/,
    :email_address => /^e=(.*)/,
    :phone_number => /^p=(.*)/,
    :connection_data => /^c=(.*)/,
    :bandwidth => /^b=(.*)/,          # Multi-type
    :timing => /^t=(.*)/,             # Multi-type
    :repeat_times => /^r=(.*)/,       # Multi-type
    :time_zones => /^z=(.*)/,         # Multi-type
    :encryption_keys => /^k=(.*)/,    # Multi-type
    :attributes => /^a=(.*)/
  }

  def self.parse_sdp sdp_text
    sdp = {}

    SDP_TYPE.each_pair do |sdp_type, regex|
      sdp_text =~ regex

      if sdp_type == :origin
        sdp[sdp_type] = parse_origin $1
      elsif sdp_type == :connection_data
        sdp[sdp_type] = parse_connection_data $1
      else
        sdp[sdp_type] = $1
      end
    end

    sdp
  end

  def self.parse_origin origin_line
    origin = {}
    origin_params = origin_line.split(" ")
    origin[:username]         = origin_params[0]
    origin[:session_id]       = origin_params[1]
    origin[:session_version]  = origin_params[2].to_i # Should be NTP timestamp
    origin[:net_type]         = origin_params[3]
    origin[:address_type]        = origin_params[4]
    origin[:unicast_address]  = origin_params[5]

    origin
  end

  # c= can show up multiple times...
  # If :connection_address has a trailing /127 (ex), 127 = ttl; only IP4 though.
  def self.parse_connection_data connection_data_line
    connection_data = {}
    connection_data_params = connection_data_line.split(" ")
    connection_data[:net_type]            = connection_data_params[0]
    connection_data[:address_type]           = connection_data_params[1]
    connection_data[:connection_address]  = connection_data_params[2]

    connection_data
  end

  # TODO: The origin <username> MUST NOT contain spaces.
  # TODO: Its
  #      usage is up to the creating tool, so long as <sess-version> is
  #      increased when a modification is made to the session data.  Again,
  #      it is RECOMMENDED that an NTP format timestamp is used.
  def initialize fields={}
    self[:version] = SDP_VERSION || fields[:version]
    self[:origin] = Hash.new
    self[:origin][:username] = Etc.getlogin  || fields[:username]
    ntp = Net::NTP.get
    self[:origin][:session_id] = ntp.receive_timestamp.to_i  || fields[:origin][:session_id]
    self[:origin][:session_version] = ntp.receive_timestamp.to_i || fields[:origin][:session_version]
    self[:origin][:net_type] = 'IN' || fields[:origin][:net_type]
    self[:origin][:address_type] = :IP4 || fields[:origin][:address_type]
  end
end