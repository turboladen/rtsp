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
        add_route(:play, stream)
      end

      def add_route(verb, stream_path=nil)
        @routes ||= {}
        @routes[verb.to_sym] ||= []
        @routes[verb.to_sym] << stream_path
      end

      # @return [Array]
      def supported_methods
        @routes.keys.map { |verb| verb.to_s.upcase }.uniq
      end

      # Methods that can be called while in the given state.
      #
      # @return [Array]
      def allowed_methods(state)
        case state
        when :init
          methods = supported_methods
          methods.delete 'PLAY'
          methods.delete 'PAUSE'
          methods.delete 'RECORD'

          methods
        else
          supported_methods
        end
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
      # @todo Requested Transport might be for multiple streams--does this parse right?
      def setup(env)
        cseq = env['RTSP_CSEQ']
        stream_class = @stream_types[env['PATH_INFO']]
        return not_found(cseq) if stream_class.nil?

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
        session = RTSP::Session.new
        session.streams << stream
        sessions.add session
        session.setup

        transports = session.streams.map do |stream|
          stream.transport_data(env)
        end.join(',')

        RTSP::Response.new(200).with_headers({
          'CSeq' => cseq,
          'Session' => "#{session.id};timeout=#{session.timeout}",
          'Transport' => transports
        })
      end

      def play(env)
        cseq = env['RTSP_CSEQ']
        requested_session = env['RTSP_SESSION']

        unless sessions.has_key? requested_session[:id]
          return session_not_found(cseq)
        end

        session = sessions[requested_session[:id]]

        unless session.state == :ready
          puts "Current session state: #{session.state}"
          return method_not_valid_in_this_state(cseq, session.state)
        end

        range = env['RTSP_RANGE']
        m = range.match(/npt=(?<start>[^-]+)(-(?<stop>\S+))?/)
        start = m[:start]
        stop = m[:stop] if m[:stop]
        #RTSP::Logger.log "Range: #{range}; start: #{start}; stop: #{stop}"
        puts "Range: #{range}; start: #{start}; stop: #{stop}"
        session.play(start, stop)

        RTSP::Response.new(200).with_headers({
          'CSeq' => cseq,
          'Session' => "#{session.id};timeout=#{session.timeout}",
          'Range' => "npt=#{start}-#{stop}"
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
        RTSP::Response.new(451).with_headers('CSeq' => cseq)
      end

      def session_not_found(cseq)
        RTSP::Response.new(454).with_headers('CSeq' => cseq)
      end

      def method_not_valid_in_this_state(cseq, state)
        RTSP::Response.new(455).with_headers('CSeq' => cseq,
          'Allow' => allowed_methods(state))
      end
    end
  end
end
