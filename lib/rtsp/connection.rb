require 'rack/utils'
require 'socket'

require_relative 'logger'
require_relative 'request'
require_relative 'response'


module RTSP

  class Connection < EventMachine::Connection
    include LogSwitch::Mixin

    attr_reader :cseq
    attr_accessor :app

    def initialize(host, port)
      @host, @port = host, port
    end

    def receive_data(data)
      request = RTSP::Request.parse(data)

      @remote_address, @remote_port = peer_info

      request.env['REQUEST_METHOD'] = request.method_type.to_s.upcase
      request.env['SERVER_SOFTWARE'] = 'RubyRTSP server CHANGE ME'
      request.env['SERVER_NAME'] = Socket.gethostname
      request.env['SERVER_PORT'] = @port
      request.env['SCRIPT_NAME'] = ''
      request.env['PATH_INFO'] = URI(request.uri).path
      request.env['QUERY_STRING'] = URI(request.uri).query || ''
      request.env['rack.url_scheme'] = URI(request.uri).scheme
      request.env['rtsp.remote_address'] = @remote_address
      request.env['rtsp.remote_port'] = @remote_port

      request.headers.each do |name, value|
        env_name = name.gsub(/-/, "_").upcase

        next if name.match(/CONTENT_LENGTH/)

        if name.match(/^CONTENT_TYPE$/)
          request.env[env_name] = value
        else
          request.env["RTSP_#{env_name}"] = value
        end
      end

      #begin
        status, headers, body = @app.call(request.env)
        headers ||= {}
      #rescue Rack::Lint::LintError => ex
      #  raise unless ex.message.match /url_scheme.+rtspu?/
      #  p Rack::Server.middleware
      #  remove_rack_lint
      #  p Rack::Server.middleware
      #  status, headers, body = @app.call(request.env)
      #end

      response = RTSP::Response.new(status, body).with_headers(headers)
      send_data(response.to_s)
    end

=begin
    def remove_rack_lint
      Rack::Server.middleware.each do |env_name, mw_array|
        puts "env: #{env_name}"
        puts "mw array: #{mw_array}"

        mw_array.each do |mw|
          puts "mw: #{mw}"
          @app.use mw unless mw.first == Rack::Lint
        end
      end
    end
=end

    # Gets the IP and port from the peer that just sent data.
    #
    # @return [Array<String,Fixnum>] The IP and port.
    def peer_info
      peer_bytes = get_peername[2, 6].unpack("nC4")
      port = peer_bytes.first.to_i
      ip = peer_bytes[1, 4].join(".")

      [ip, port]
    end
  end
end
