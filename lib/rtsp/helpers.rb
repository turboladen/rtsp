require File.expand_path(File.dirname(__FILE__) + '/global')

module RTSP
  module Helpers
    include RTSP::Global

    # Takes the URL given and turns it into a URI.  This allows for enforcing
    # values for each part of the URI.
    #
    # @param [String] The URL to turn in to a URI.
    # @return [URI]
    def build_resource_uri_from url
      url = "rtsp://#{url}" unless url =~ /^rtsp/

      resource_uri = URI.parse url
      resource_uri.port ||= DEFAULT_PORT

      resource_uri
    end
  end
end
