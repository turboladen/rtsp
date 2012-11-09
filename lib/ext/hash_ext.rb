require_relative 'symbol_ext'

class Hash

  # Turns headers from Hash(es) into a String, where each element
  # is a String in the form: [Header Type]: value(s)\r\n.
  #
  # @return [String]
  def to_headers_s
    header_string = assemble_headers

    order_headers(header_string)
  end

  private

  def assemble_headers
    self.inject("") do |result, (key, value)|
      header_name = key.to_header_name

      if value.is_a?(Hash) || value.is_a?(Array)
        values = if header_name == "Content-Type"
          values_to_s(value, ", ")
        else
          values_to_s(value)
        end

        result << "#{header_name}: #{values}\r\n"
      else
        result << "#{header_name}: #{value}\r\n"
      end

      result
    end
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
  def values_to_s(values, separator=";")
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
