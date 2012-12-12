require 'uri'

module URI
  class RTSP < HTTP
    DEFAULT_PORT = 554

    def request_uri
      to_s
    end

    def multicast?
      m = host.match(/^(?<octet>\d\d?\d?)/)

      m[:octet].to_i >= 224 && m[:octet].to_i <= 239
    end
  end

  @@schemes['RTSP'] = RTSP

  class RTSPU < HTTP
    DEFAULT_PORT = 554

    def request_uri
      to_s
    end

    def multicast?
      m = host.match(/^(?<octet>\d\d?\d?)/)

      m[:octet].to_i >= 224 && m[:octet].to_i <= 239
    end
  end

  @@schemes['RTSPU'] = RTSPU
end
