require 'sdp'

module RTSP

  # This module defines the template strings that make up RTSP methods.  Other
  # objects should use these for building request messages to communicate in
  # RTSP.
  module RequestMessages
    RTSP_VER = "RTSP/1.0"
    RTSP_ACCEPT_TYPE = "application/sdp"
    RTP_DEFAULT_CLIENT_PORT = 9000
    RTP_DEFAULT_PACKET_TYPE = "RTP/AVP"
    RTP_DEFAULT_ROUTING = "unicast"
    RTSP_DEFAULT_SEQUENCE_NUMBER = 1
    RTSP_DEFAULT_NPT = "0.000-"
    RTSP_DEFAULT_LANGUAGE = "en-US"

    def self.execute(method, resource_url, new_headers={}, body=nil)
      body = default_body(method) unless body
      new_headers[:content_length] = body.length if body

      new_headers[:cseq] ||= RTSP_DEFAULT_SEQUENCE_NUMBER
      all_headers = default_headers(method)
      all_headers.merge! new_headers

      message = "#{method.upcase} #{resource_url} #{RTSP_VER}\r\n"
      message << headers_to_s(all_headers)
      message << "\r\n"
      message << "#{body}"

      message
    end

    # @return [Hash] The default headers for the given method.
    def self.default_headers(method)
      case method
      when :describe
        { :accept => RTSP_ACCEPT_TYPE }
      when :announce
        { :content_type => RTSP_ACCEPT_TYPE }
      when :setup
        transport = "#{RTP_DEFAULT_PACKET_TYPE};"
        transport << "#{RTP_DEFAULT_ROUTING};"
        transport << "client_port=#{RTP_DEFAULT_CLIENT_PORT}-#{RTP_DEFAULT_CLIENT_PORT + 1}"
        { :transport => transport }
      else
        {}
      end
    end

    def self.default_body(method)
      case method
      when :announce
        SDP::Description.new.to_s
      else
        nil
      end
    end

    # PLAY request message as defined in section 10.5 of the RFC doc.
    #
    # @param [String] stream
    # @param [Fixnum] session
    # @param [Hash] headers RTSP headers to send.
    # @return [String] The formatted request message to send.
    def self.play(stream, headers={})
      headers[:cseq]      ||= RTSP_DEFAULT_SEQUENCE_NUMBER
      headers[:range]     ||= { :npt => RTSP_DEFAULT_NPT }

      message =  "PLAY #{stream} #{RTSP_VER}\r\n"

      message << headers_to_s(headers)
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
      options[:cseq] ||= RTSP_DEFAULT_SEQUENCE_NUMBER
      message =  "TEARDOWN #{stream} #{RTSP_VER}\r\n"
      message << "CSeq: #{options[:cseq]}\r\n"
      message << "Session: #{session}\r\n"
      message << "\r\n"
    end

    # @return [String] The formatted request message to send.
    def self.get_parameter(stream, session, headers={})
      message =  "GET_PARAMETER #{stream} #{RTSP_VER}\r\n"
      message << "CSeq: #{headers[:cseq]}\r\n"
      message << "Content-Type: #{headers[:content_type]}\r\n"
      message << "Content-Length: #{headers[:content_length]}\r\n"
      message << "Session: #{session}\r\n"
      message << "\r\n"
    end

    # @return [String] The formatted request message to send.
    def self.set_parameter(stream, headers={})
      message =  "SET_PARAMETER #{stream} #{RTSP_VER}\r\n"
      message << "CSeq: #{headers[:cseq]}\r\n"
      message << "Content-Type: #{headers[:content_type]}\r\n"
      message << "Content-Length: #{headers[:content_length]}\r\n"
      message << "\r\n"
    end

    # @return [String] The formatted request message to send.
    def self.record(stream, session, headers={})
      message =  "RECORD #{stream} #{RTSP_VER}\r\n"
      message << "CSeq: #{headers[:cseq]}\r\n"
      message << "Session: #{session}\r\n\r\n"
      message << "Conference: #{headers[:conference]}\r\n"
      message << "\r\n"
    end

    # Turns headers from Hash(es) into a String, where each element
    # is a String in the form: [Header Type]: value(s)\r\n.
    #
    # @param [Hash] headers The headers to put to string.
    # @return [String]
    def self.headers_to_s headers
      headers.inject("") do |result, (key, value)|
        header_name = key.to_s.split(/_/).map { |header| header.capitalize }.join('-')

        header_name = "CSeq" if header_name == "Cseq"

        if value.is_a?(Hash) || value.is_a?(Array)
          if header_name == "Content-Type"
            values = values_to_s(value, ", ")
          else
            values = values_to_s(value)
          end

          result << "#{header_name}: #{values}\r\n"
        else
          result << "#{header_name}: #{value}\r\n"
        end

        result
      end
    end

    # Turns header values into a single string.
    #
    # @param [] values The header values to put to string.
    # @param [String] separator The character to use to separate multiple values
    # that define a header.
    # @return [String] The header values as a single string.
    def self.values_to_s(values, separator=";")
      result = values.inject("") do |values_string, (header_field, header_field_value)|
        if header_field.is_a? Symbol
          values_string << "#{header_field}=#{header_field_value}"
        elsif header_field.is_a? Hash
          values_string << values_to_s(header_field)
        else
          values_string << header_field.to_s
        end

        values_string + separator
      end

      result.sub!(/#{separator}$/, '') if result.end_with? separator
    end
  end
end
