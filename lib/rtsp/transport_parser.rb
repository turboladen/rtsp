require 'parslet'

module RTSP
  class TransportParser < Parslet::Parser

    def initialize
      super
    end

    rule(:transport_specifier) do
      match('[A-Z]').repeat(3).as(:protocol) >> forward_slash >>
          match('[A-Z]').repeat(3).as(:profile) >>
          (forward_slash >> match('[A-Z]').repeat(3).as(:lower_transport)).maybe
    end

    rule(:broadcast_type) do
      str('unicast')
    end

    rule(:client_port) do
      str('client_port=') >> number.as(:rtp) >> dash >> number.as(:rtcp)
    end

    rule(:interleaved) do
      str('interleaved=') >> number.as(:rtp_channel) >> dash >>
          number.as(:rtcp_channel)
    end

    rule(:number)         { match('[\d]').repeat }
    rule(:forward_slash)  { match('[/]') }
    rule(:semi_colon)     { match('[;]') }
    rule(:dash)           { match('[-]') }

    rule(:header_field) do
      transport_specifier >>
          (semi_colon >> broadcast_type.as(:broadcast_type)).maybe >>
          (semi_colon >> client_port.as(:client_port)).maybe >>
          (semi_colon >> interleaved.as(:interleaved)).maybe

    end

    root :header_field
  end
end
