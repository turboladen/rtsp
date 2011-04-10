require 'uri'
require_relative 'global'
require_relative 'error'

module RTSP
  module Helpers
    include RTSP::Global

    # Takes the URL given and turns it into a URI.  This allows for enforcing
    # values for each part of the URI.
    #
    # @param [String] The URL to turn in to a URI.
    # @return [URI]
    def build_resource_uri_from url
      if url.is_a? String
        url = "rtsp://#{url}" unless url =~ /^rtsp/

        resource_uri = URI.parse url
        resource_uri.port ||= DEFAULT_RTSP_PORT

        resource_uri

      else
        raise RTSP::Error, "url must be a String."
      end
    end
  end
end
