require 'uri'

module URI
  class RTSP < HTTP
    DEFAULT_PORT = 554

    def request_uri
      to_s
    end

    def multicast?
      !!host.match(/^239/)
    end
  end

  @@schemes['RTSP'] = RTSP

  class RTSPU < HTTP
    DEFAULT_PORT = 554

    def request_uri
      to_s
    end

    def multicast?
      !!host.match(/^239/)
    end
  end

  @@schemes['RTSPU'] = RTSPU
end
