class Symbol

  # Converts a snake-case header name (that's most likely the key in a Hash) to
  # a RTSP/HTTP style header name.
  #
  # @example
  #   :content_type.to_header_name    # => 'Content-Type'
  def to_header_name
    name = self.to_s.split(/_/).map do |header|
      header.capitalize
    end.join('-')

    name = "CSeq" if name == "Cseq"

    name
  end
end
