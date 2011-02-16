module RTSP
  module Helpers
    RTSP_DEFAULT_PORT = 554

    # Takes the URL given and turns it into a URI.  This allows for enforcing
    # values for each part of the URI.
    #
    # @param [String] The URL to turn in to a URI.
    # @return [URI]
    def build_resource_uri_from url
      url = "rtsp://#{url}" unless url =~ /^rtsp/

      resource_uri = URI.parse url
      # Not sure if this should be enforced; commenting out for now.
      resource_uri.port ||= RTSP_DEFAULT_PORT

      resource_uri
    end
  end
end
