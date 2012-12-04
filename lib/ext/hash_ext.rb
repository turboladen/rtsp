class Hash

  # Turns headers from Hash(es) into a String, where each element
  # is a String in the form: [Header Type]: value(s)\r\n.
  #
  # @return [String]
  def to_headers_s
    #order_headers(assemble_headers)
    assemble_headers
  end

  private

=begin
  def assemble_headers
    self.inject("") do |result, (key, value)|
      #header_name = key.to_header_name
      header_name = key.is_a?(Symbol) ? key.to_header_name : key

      if value.is_a?(Hash) || value.is_a?(Array)
        values = case header_name
        when "Content-Type"
          basic_header_values_to_s(value, ", ")
        when "Session"
          session_values_to_s(value)
        when "Transport"
          transport_values_to_s(value)
        else
          basic_header_values_to_s(value)
        end

        result << "#{header_name}: #{values}\r\n"
      else
        result << "#{header_name}: #{value}\r\n"
      end

      result
    end
  end
=end
  def assemble_headers
    self.inject('') do |result, (field_name, value)|
      result << "#{field_name}: #{value}\r\n"

      result
    end
  end

=begin
  # Takes the values from the +transport_hash+ and turns them into a String,
  # which is ready to add to the Transport header.
  #
  # @param [Hash] transport_hash The Hash of params that make up the transport
  #   header values.
  # @return [String] The Transport header values as a String.
  def transport_values_to_s(transport_hash)
    v = "#{transport_hash[:streaming_protocol]}/#{transport_hash[:profile]}"

    if transport_hash.has_key?(:lower_transport)
      v << "/#{transport_hash[:lower_transport]}"
    end

    v << ";#{transport_hash[:broadcast_type]}"

    if transport_hash.has_key? :interleaved
      v << ";interleaved=#{transport_hash[:interleaved][:start]}"
      v << "-#{transport_hash[:interleaved][:end]}"
    end

    if transport_hash.has_key? :append
      v << ";append"
    end

    [:destination, :ttl, :layers, :ssrc].each do |k|
      if transport_hash.has_key?(k)
        v << ";#{k}=#{transport_hash[k]}"
      end
    end

    if transport_hash.has_key? :mode
      v << ";mode=\"#{transport_hash[:mode]}\""
    end

    [:client_port, :server_port, :port].each do |k|
      if transport_hash.has_key?(k)
        v << ";#{k}=#{transport_hash[k][:rtp]}-#{transport_hash[k][:rtcp]}"
      end
    end

    v
  end

  # Takes the values from the +session_hash+ and turns them into a String,
  # which is ready to add to the Session header.
  #
  # @param [Hash] session_hash The Hash of params that make up the session
  #   header values.
  # @return [String] The Session header values as a String.
  def session_values_to_s(session_hash)
    v = "#{session_hash[:session_id]}"

    if session_hash.has_key?(:timeout)
      v << ";timeout=#{session_hash[:timeout]}"
    end

    v
  end

  def order_headers(header_string)
    arr = header_string.split "\r\n"

    # Move the Session header to the top
    session_index = arr.index { |a| a =~ /Session/ }
    unless session_index.nil?
      session = arr.delete_at(session_index)
      arr.unshift(session)
    end

    # Move the User-Agent header to the top
    user_agent_index = arr.index { |a| a =~ /User-Agent/ }
    unless user_agent_index.nil?
      user_agent = arr.delete_at(user_agent_index)
      arr.unshift(user_agent)
    end

    # Move the CSeq header to the top
    if header_string =~ /CSeq/
      cseq_index = arr.index { |a| a =~ /CSeq/ }
      cseq = arr.delete_at(cseq_index)
      arr.unshift(cseq)
    end

    # Put it all back to a String
    header_string = arr.join("\r\n")
    header_string << "\r\n"
  end

  # Turns header values into a single string.
  #
  # @param [Hash,Array] values The header values to put to string.
  # @param [String] separator The character to use to separate multiple
  #   values that define a header.
  # @return [String] The header values as a single string.
  def basic_header_values_to_s(values, separator=";")
    result = values.inject("") do |values_string, (header_field, header_field_value)|
      values_string << if header_field.is_a? Symbol
        "#{header_field}=#{header_field_value}"
      #elsif header_field.is_a? Hash
      #  basic_header_values_to_s(header_field)
      else
        header_field.to_s
      end

      puts "values string: #{values_string}"
      values_string + separator
    end

    result.sub!(/#{separator}$/, '') if result.end_with? separator
  end
=end
end
