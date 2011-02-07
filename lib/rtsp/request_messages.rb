require 'sdp'

module RTSP

  # This module defines the template strings that make up RTSP methods.  Other
  # objects should use these for building request messages to communicate in
  # RTSP.
  module RequestMessages
    RTSP_VER = "RTSP/1.0"
    RTSP_ACCEPT_TYPE = "application/sdp"
    RTP_DEFAULT_PORT = 9000
    RTP_DEFAULT_PACKET_TYPE = "RTP/AVP"
    RTP_DEFAULT_ROUTING = "unicast"
    RTSP_DEFAULT_SEQUENCE_NUMBER = 1
    RTSP_DEFAULT_NPT = "0.000-"

    # OPTIONS request message as defined in section 10.1 of the RFC doc.
    #
    # @param [String] stream
    # @param [Fixnum] sequence
    # @return [String] The formatted request message to send.
    def self.options(stream, sequence=RTSP_DEFAULT_SEQUENCE_NUMBER)
      message =  "OPTIONS #{stream} #{RTSP_VER}\r\n"
      message << "CSeq: #{sequence}\r\n"
      message << "\r\n"
    end

    # See section 10.2
    # 
    # @param [String] stream
    # @param [Hash] options
    # @option options [Number] sequence
    # @option options [Array<String>] accept The list of description formats the
    # client understands.
    # @return [String] The formatted request message to send.
    def self.describe(stream, options={})
      options[:sequence] ||= RTSP_DEFAULT_SEQUENCE_NUMBER
      options[:accept]   ||= [RTSP_ACCEPT_TYPE]

      # Comma-separate these
      accepts = options[:accept] * ", "

      message =  "DESCRIBE #{stream} #{RTSP_VER}\r\n"
      message << "CSeq: #{options[:sequence]}\r\n"
      message << "Accept: #{accepts}\r\n"
      message << "\r\n"
    end

    # ANNOUNCE request message as defined in section 10.3 of the RFC doc.
    #
    # @param [String] stream
    # @param [Number] session
    # @param [Hash] options
    # @option options [Fixnum] :sequence The sequence number to use.
    # @option options [String] :content_type Defaults to 'application/sdp'.
    # @option options [SDP::Description] The SDP description to announce.
    # @return [String] The formatted request message to send.
    def self.announce(stream, session, options={})
      sequence =        options[:sequence]      || RTSP_DEFAULT_SEQUENCE_NUMBER
      content_type =    options[:content_type]  || RTSP_ACCEPT_TYPE
      sdp =             options[:sdp]           || SDP::Description.new
      content_length =  sdp.to_s.length         || 0

      message =  "ANNOUNCE #{stream} #{RTSP_VER}\r\n"
      message << "CSeq: #{sequence}\r\n"
      message << "Date: \r\n"
      message << "Session: #{session}\r\n"
      message << "Content-Type: #{content_type}\r\n"
      message << "Content-Length: #{content_length}\r\n"
      message << "\r\n"
      message << sdp.to_s
    end

    # SETUP request message as defined in section 10.4 of the RFC doc.
    #
    # @param [String] track Track to prep to stream.
    # @param [Hash] options
    # @option options [Fixnum] :sequence Defaults to 1.
    # @option options [String] :transport Defaults to RTP/AVP.
    # @option options [String] :routing Defaults to unicast.
    # @option options [Fixnum] :client_port Defaults to 9000.
    # @option options [Fixnum] :server_port
    # @return [String] The formatted request message to send.
    def self.setup(track, options={})
      sequence =        options[:sequence]    || RTSP_DEFAULT_SEQUENCE_NUMBER
      transport_spec =  options[:transport_spec]   || RTP_DEFAULT_PACKET_TYPE
      routing =         options[:routing]     || RTP_DEFAULT_ROUTING
      destination =     options[:destination] || nil
      client_port =     options[:client_port] || RTP_DEFAULT_PORT
      server_port =     options[:server_port] || nil
      port =            options[:port]        || nil

      message =  "SETUP #{track} #{RTSP_VER}\r\n"
      message << "CSeq: #{sequence}\r\n"
      message << "Transport: #{transport_spec};"
      message << "#{destination};"          if destination
      message << "#{routing};"
      message << "port=#{port}-#{port + 1}" if port
      message << "client_port=#{client_port}-#{client_port + 1}"
      message << ";server_port=#{server_port}-#{server_port + 1}" if server_port
      message << "\r\n"
      message << "\r\n"
    end

    # PLAY request message as defined in section 10.5 of the RFC doc.
    #
    # @param [String] stream
    # @param [Fixnum] session
    # @param [Hash] headers RTSP headers to send.
    # @return [String] The formatted request message to send.
    def self.play(stream, headers={})
      headers[:sequence]  ||= RTSP_DEFAULT_SEQUENCE_NUMBER
      headers[:range]     ||= { :npt => RTSP_DEFAULT_NPT }

      message =  "PLAY #{stream} #{RTSP_VER}\r\n"

      header_list = stringify_headers(headers)
      header_list.each { |header| message << "#{header}\r\n" }
      message << "\r\n"

      message
    end

    # @return [String] The formatted request message to send.
    def self.pause(stream, session, sequence)
      message =  "PAUSE #{stream} #{RTSP_VER}\r\n"
      message << "CSeq: #{sequence}\r\n"
      message << "Session: #{session}\r\n"
      message << "\r\n"
    end

    # @return [String] The formatted request message to send.
    def self.teardown(stream, session, options={})
      options[:sequence] ||= RTSP_DEFAULT_SEQUENCE_NUMBER
      message =  "TEARDOWN #{stream} #{RTSP_VER}\r\n"
      message << "CSeq: #{options[:sequence]}\r\n"
      message << "Session: #{session}\r\n"
      message << "\r\n"
    end

    # @return [String] The formatted request message to send.
    def self.get_parameter(stream, session, options={})
      message =  "GET_PARAMETER #{stream} #{RTSP_VER}\r\n"
      message << "CSeq: #{options[:sequence]}\r\n"
      message << "Content-Type: #{options[:content_type]}\r\n"
      message << "Content-Length: #{options[:content_length]}\r\n"
      message << "Session: #{session}\r\n"
      message << "\r\n"
    end

    # @return [String] The formatted request message to send.
    def self.set_parameter(stream, options={})
      message =  "SET_PARAMETER #{stream} #{RTSP_VER}\r\n"
      message << "CSeq: #{options[:sequence]}\r\n"
      message << "Content-Type: #{options[:content_type]}\r\n"
      message << "Content-Length: #{options[:content_length]}\r\n"
      message << "\r\n"
    end

    # @return [String] The formatted request message to send.
    def self.record(stream, session, options={})
      message =  "RECORD #{stream} #{RTSP_VER}\r\n"
      message << "CSeq: #{options[:sequence]}\r\n"
      message << "Session: #{session}\r\n\r\n"
      message << "Conference: #{options[:conference]}\r\n"
      message << "\r\n"
    end

    # Turns headers from Hash(es) into an Array of Strings, where each element
    # is a String in the form: [Header Type]: value(s).
    #
    # @param [Hash] headers The headers to stringify.
    # @return [Array<String>]
    def self.stringify_headers headers
      headers.inject([]) do |result, (key, value)|
        header_name = key.to_s.split(/_/).map { |header| header.capitalize }.join('-')

        header_name = "CSeq" if header_name == "Sequence"

        if value.is_a?(Hash) || value.is_a?(Array)
          if header_name == "Content-Type"
            values = stringify_values(value, ", ")
          else
            values = stringify_values(value)
          end

          result << "#{header_name}: #{values}"
        else
          result << "#{header_name}: #{value}"
        end

        result
      end
    end

    # Turns header values into a single string.
    #
    # @param [] values The header values to stringify.
    # @param [String] separator The character to use to separate multiple values
    # that define a header.
    # @return [String] The header values as a single string.
    def self.stringify_values(values, separator=";")
      result = values.inject("") do |values_string, (header_field, header_field_value)|
        if header_field.is_a? Symbol
          values_string << "#{header_field}=#{header_field_value}"
        elsif header_field.is_a? Hash
          values_string << stringify_values(header_field)
        else
          values_string << header_field.to_s
        end

        values_string + separator
      end

      result.sub!(/#{separator}$/, '') if result.end_with? separator
    end
  end
end
