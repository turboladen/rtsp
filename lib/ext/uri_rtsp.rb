require 'uri'

module URI
  class RTSP < HTTP
    DEFAULT_PORT = 554

    def request_uri
      to_s
    end
  end

  @@schemes['RTSP'] = RTSP

  class RTSPU < HTTP
    DEFAULT_PORT = 554

    def request_uri
      to_s
    end
  end

  @@schemes['RTSPU'] = RTSPU
end
