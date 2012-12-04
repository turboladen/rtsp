require 'rack'
require_relative 'global'
require_relative 'logger'
require_relative 'request'
require_relative 'response'


module RTSP

  # This is the piece of an RTSP application that serves requests and responses.
  # It is *highly* based on the Thin web server.  Like thin, it listens for
  # incoming requests through a given +backend+ and forwards all requests to
  # +app+.  While RTSP is similar to HTTP, most web servers will choke on
  # parsing status lines that contain RTSP/1.0 instead of HTTP/1.1 (or 1.0).
  # This class simply gets around that, yet still provides for using Rack for
  # middleware and such.
  #
  # If you're simply looking to build an RTSP server app, look at
  # RTSP::Application; that provides the framework stuff for defining your
  # app (similar to Rails, Sinatra, etc.) and will use this.
  #
  # == TCP server
  # Create a new TCP server bound to <tt>host:port</tt> by specifying +host+ and
  # +port+.
  #
  #   RTSP::Server.start('0.0.0.0', 5554, app)
  #
  # == Rack application (+app+)
  # Like thin, this can take a block that acts as a valid Rack adapter.  It's
  # recommended, however, to use RTSP::Application to create your app, due to
  # Rack not having RTSP support built in.
  #
  #   RTSP::Server.start('0.0.0.0', 5554) do
  #     map "/test" do
  #       use Rack::Lint
  #       app = proc do |env|
  #         [200, {"Content-Type" => "text/html"}, "Hello Rack!"]
  #       end
  #
  #       run app
  #     end
  #   end
  #
  class Server
    extend RTSP::Global
    include LogSwitch::Mixin

    DEFAULT_HOST = '0.0.0.0'

    attr_accessor :app

    # Initializes the the Stream Server.
    #
    # @param [String] host IP interface to bind.
    # @param [Fixnum] port RTSP port.
    # @param [Rack::Builder] app The Rack application to use.
    # @param [Hash] options
    # @option options [Class] :backend The type of backend to use for the server.
    def initialize(host, port, app=nil, options={}, &block)
      host = host
      port = port
      @backend = select_backend(host, port, options)
      @backend.server = self
      @app = if block_given?
        Rack::Builder.new(&block).to_app
      else
        app
      end
    end

    # Shortcut for doing Server.new(...).start.
    #
    # @param [String] host
    # @param [Fixnum] port
    # @param [Hash] options
    def self.start(host=DEFAULT_HOST, port=DEFAULT_RTSP_PORT, options={}, &block)
      new(host, port, options, &block).start
    end

    # Starts the server and listens for connections.
    def start
      raise ArgumentError, 'app required' unless @app

      log "RTSP server (v#{RTSP::VERSION})"
      log "Listening on #{@backend.location}, CTRL+C to stop"

      @backend.start
    end

    # Graceful shutdown:
    # Stops the server after processing all current connections.
    # As soon as this method is called, the server stops accepting
    # new requests and wait for all current connections to finish.
    # Calling twice is the equivalent of calling <tt>#stop!</tt>.
    def stop
      if running?
        @backend.stop
        unless @backend.empty?
          log "Waiting for #{@backend.size} connection(s) to finish, " +
            "can take up to #{timeout} sec, CTRL+C to stop now"
        end
      else
        stop!
      end
    end

    # Force shutdown:
    # Stops the server closing all current connections right away.
    # This doesn't wait for connection to finish their work and send data.
    # All current requests will be dropped.
    def stop!
      log "Stopping ..."

      @backend.stop!
    end

    private

    # Register signals:
    # * TERM & QUIT calls +stop+ to shutdown gracefully.
    # * INT calls <tt>stop!</tt> to force shutdown.
    # * HUP calls <tt>restart</tt> to ... surprise, restart!
    # * USR1 reopen log files.
    def setup_signals
      trap('INT')  { stop! }
      trap('TERM') { stop }

      # Windows
      trap('QUIT') { stop }
      trap('HUP')  { stop }
    end

    # Picks the RTSP backend based on the parameters given.
    #
    # @param [Fixnum] host IP interface to bind.
    # @param [Fixnum] port RTSP port.
    # @param [Hash] options
    def select_backend(host, port, options)
      case
      when options.has_key?(:backend)
        unless options[:backend].is_a? Class
          raise ArgumentError, ":backend must be a class"
        end

        options[:backend].new(host, port, options)
      else
        require_relative 'backends/tcp_server'
        Backends::TCPServer.new(host, port)
      end
    end
  end
end
