require 'parslet'

module RTSP

  # Used for parsing the Transport header--mainly as the response from the
  # SETUP request.  The values from this are used to determine what to use for
  # other requests.
  class TransportParser < Parslet::Parser
    rule(:transport_specifier) do
      match('[A-Z]').repeat(3).as(:streaming_protocol) >> forward_slash >>
          match('[A-Z]').repeat(3).as(:profile) >>
          (forward_slash >> match('[A-Z]').repeat(3).as(:transport_protocol)).maybe
    end

    rule(:broadcast_type) do
      str('unicast')
    end

    rule(:destination) do
      str('destination=') >> ip_address
    end
    rule(:source) do
      str('source=') >> ip_address
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
          (semi_colon >> destination.as(:destination)).maybe >>
          (semi_colon >> source.as(:source)).maybe >>
          (semi_colon >> client_port.as(:client_port)).maybe >>
          (semi_colon >> server_port.as(:server_port)).maybe >>
          (semi_colon >> interleaved.as(:interleaved)).maybe

    end

    root :header_field
  end
end
