require 'parslet'

module RTSP

  # Used for parsing the Transport header--mainly as the response from the
  # SETUP request.  The values from this are used to determine what to use for
  # other requests.
  class TransportParser < Parslet::Parser
    rule(:transport_specifier) do
      match('[A-Za-z]').repeat(3).as(:streaming_protocol) >> forward_slash >>
        match('[A-Za-z]').repeat(3).as(:profile) >>
        (forward_slash >> match('[A-Za-z]').repeat(3).as(:transport_protocol)).maybe
    end

    rule(:broadcast_type) do
      str('unicast') | str('multicast')
    end

    rule(:destination) do
      str('destination=') >> ip_address.as(:destination)
    end

    rule(:source) do
      str('source=') >> ip_address.as(:source)
    end

    rule(:client_port) do
      str('client_port=') >> number.as(:rtp) >> dash >> number.as(:rtcp)
    end

    rule(:server_port) do
      str('server_port=') >> number.as(:rtp) >> dash >> number.as(:rtcp)
    end

    rule(:interleaved) do
      str('interleaved=') >> number.as(:rtp_channel) >> dash >>
        number.as(:rtcp_channel)
    end

    rule(:ttl) do
      str('ttl=') >> match('[\d]').repeat(1,3).as(:ttl)
    end

    rule(:port) do
      str('port=') >> match('[\d]').repeat(1,5).as(:rtp) >>
        dash.maybe >> match('[\d]').repeat(1,5).as(:rtcp).maybe
    end

    rule(:ssrc) do
      str('ssrc=') >> match('[0-9A-Fa-f]').repeat(8).as(:ssrc)
    end

    rule(:channel) do
      str('channel=') >> match('[\w]').repeat(1,3).as(:channel)
    end

    rule(:address) do
      str('address=') >> match('[\S]').repeat.as(:address)
    end

    rule(:mode) do
      str('mode=') >> str('"').maybe >> match('[A-Za-z]').repeat.as(:mode) >>
        str('"').maybe
    end

    rule(:ip_address) do
      match('[\d]').repeat(1,3) >> str('.') >>
        match('[\d]').repeat(1,3) >> str('.') >>
        match('[\d]').repeat(1,3) >> str('.') >>
        match('[\d]').repeat(1,3)
    end

    rule(:number)         { match('[\d]').repeat }
    rule(:forward_slash)  { match('[/]') }
    rule(:semi_colon)     { match('[;]') }
    rule(:dash)           { match('[-]') }

    rule(:header_field) do
      transport_specifier >>
        (semi_colon >> broadcast_type.as(:broadcast_type)).maybe >>
        (semi_colon >> destination).maybe >>
        (semi_colon >> source).maybe >>
        (semi_colon >> client_port.as(:client_port)).maybe >>
        (semi_colon >> source).maybe >>
        (semi_colon >> server_port.as(:server_port)).maybe >>
        (semi_colon >> source).maybe >>
        (semi_colon >> client_port.as(:client_port)).maybe >>
        (semi_colon >> interleaved.as(:interleaved)).maybe >>
        (semi_colon >> ttl).maybe >>
        (semi_colon >> port.as(:port)).maybe >>
        (semi_colon >> ssrc).maybe >>
        (semi_colon >> channel).maybe >>
        (semi_colon >> address).maybe >>
        (semi_colon >> mode).maybe
    end

    root :header_field
  end
end
