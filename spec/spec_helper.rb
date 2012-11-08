require 'simplecov'

SimpleCov.start do
  add_filter "/spec/"
end

require 'rspec'
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'rtsp'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }


# Define #describe so when RTSP::Message calls #method_missing, RSpec doesn't
# get in the way (and cause tests to fail).
module RTSP
  class Message
    def self.describe request_uri
      self.new(:describe, request_uri)
    end
  end
end
