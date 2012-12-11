require 'uri'

module URI
  class RTSP < Generic
    DEFAULT_PORT = 554
  end

  @@schemes['RTSP'] = RTSP

  class RTSPU < Generic
    DEFAULT_PORT = 554
  end

  @@schemes['RTSPU'] = RTSPU
end
