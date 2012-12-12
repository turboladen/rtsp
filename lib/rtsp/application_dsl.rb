require_relative 'logger'
require_relative 'session'
require_relative 'session_manager'


module RTSP
  module ApplicationDSL
    def self.included(base)
      base.extend(DSLMethods)
      base.extend(RTSPMethods)
    end

    module DSLMethods
      include LogSwitch::Mixin

      def stream(path)
        puts "Setting up new stream at: #{path}"
        @description ||= default_description
        @stream_types ||= {}

        stream_class = instance_eval <<-STREAM
          class ::RTSP::Stream#{path.sub(/^\//, '').camel_case} < RTSP::AbstractStream
            self
          end
        STREAM

        stream_class.mount_path = path

        yield stream_class

        if @stream_types.has_key? path
          raise "Can't define more than 1 stream at the same path.  Path: #{path}"
        end

        @stream_types[path] = stream_class
        @description.add_group stream_class.description

        RTSP::Logger.log "Updated description: #{@description}"
        add_routes_for(path)
      end

      def add_routes_for(stream)
        add_route(:options)
        add_route(:describe, stream)
        add_route(:setup, stream)
      end

      def add_route(verb, stream_path=nil)
        @routes ||= {}
        @routes[verb.to_sym] ||= []
        @routes[verb.to_sym] << stream_path
      end

      def supported_methods
        @routes.keys.map { |verb| verb.to_s.upcase }.uniq
      end

      private

      # @return [SDP::Description]
      def default_description
        sdp = SDP::Description.new.seed!
        sdp.session_section.session_name.name = "Ruby RTSP Stream"

        sdp.session_section.remove_field do |f|
          f.sdp_type == :attribute && f.type == 'tool' && f.value.match(/RubySDP/)
        end

        sdp.session_section.add_field "a=tool:RubyRTSP #{RTSP::VERSION}"
        #sdp.session_section.add_field "a=control:*"

        sdp
      end
    end

    module RTSPMethods
      # Handles the options request.
      #
      # @param [Array] env The Rack environment.
      # @return [RTSP::Response] Response headers and body.
      def options(env)
        RTSP::Response.new(200).with_headers({
          'CSeq' => env['RTSP_CSEQ'],
          'Public' => self.supported_methods.join(', ')
        })
      end

      # @param [Array] env The Rack environment.
      # @return [RTSP::Response] Response headers and body.
      def describe(env)
        cseq = env['RTSP_CSEQ']

        if env['RTSP_ACCEPT'] &&
          env['RTSP_ACCEPT'].match(/application\/sdp/)
          content_type = 'application/sdp'
        else
          RTSP::Logger.log "Unknown Accept types: #{env['RTSP_ACCEPT']}", :warn
          return parameter_not_understood(cseq)
        end

        RTSP::Response.new(200).with_headers_and_body({
          'CSeq' => cseq,
          'Content-Type' => content_type,
          'Content-Base' => content_base(env),
          body: @description.to_s
        })
      end

      # @param [Array] env The Rack environment.
      # @return [RTSP::Response] Response headers and body.
      # @todo If aggregate stream is requested, add all stream types to the new session.
      def setup(env)
        cseq = env['RTSP_CSEQ']
        stream_class = @stream_types[env['PATH_INFO']]
        return not_found(cseq) if stream_class.nil?

        # Set up Transport based on request for multicast/unicast

        if env['RTSP_SESSION']
          requested_session = env['RTSP_SESSION']

          if sessions.has_key? requested_session[:id]
            return RTSP::Response(200).with_headers({
              'CSeq' => cseq,
              'Session' => requested_session[:id],
              #'Transport' => ''
            })
          else
            return session_not_found(cseq)
          end
        end

        RTSP::Logger.log "Requested Transport info: #{env['RTSP_TRANSPORT']}"
        stream = stream_class.new
        p stream
        session = RTSP::Session.new
        session.streams << stream
        p session
        sessions.add session

        p env
=begin
        @session = @session.next
        server_port = @stream_server.setup_streamer(@session,
          request.transport_url, request.stream_index)
        response = []
        transport = generate_transport(request, server_port)
        response << "Transport: #{transport.join}"
        response << "Session: #{@session}"
        response << "\r\n"

        [response]
=end
        RTSP::Response.new(200).with_headers({
          'CSeq' => env['RTSP_CSEQ'],
          'Session' => "#{session.id};timeout=#{session.timeout}",
          'Transport' => session.transport_data(env)
        })
      end

      def sessions
        @sessions ||= RTSP::SessionManager.new
      end

      def content_base(env)
        scheme = env['rack.url_scheme']
        host = env['SERVER_NAME']
        port = env['SERVER_PORT']
        path = env['PATH_INFO']
        url = "#{scheme}://#{host}"
        url << ":#{port}" unless port.to_s.empty?
        url << path

        url
      end

      def not_found(cseq)
        RTSP::Response.new(404).with_headers('CSeq' => cseq)
      end

      def parameter_not_understood(cseq)
        RTSP::Response(451).with_headers('CSeq' => cseq)
      end

      def session_not_found(cseq)
        RTSP::Response(454).with_headers('CSeq' => cseq)
      end
    end
  end
end
