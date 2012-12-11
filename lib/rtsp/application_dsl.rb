require_relative 'logger'


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

        stream_class = create_stream_class(path)
        @description ||= default_description
        @stream_types ||= {}

        yield stream_class

        @stream_types[path] = stream_class
        @description.add_group stream_class.description

        RTSP::Logger.log "Updated description: #{@description}"
        add_routes_for(path)
      end

      def add_routes_for(stream)
        add_route(:options)
        add_route(:describe, stream)
      end

      def add_route(verb, stream=nil)
        @routes ||= {}
        @routes[verb.to_sym] = stream
      end

      def supported_methods
        @routes.keys.map { |verb| verb.to_s.upcase }
      end

      def create_stream_class(path)
        Class.new(::RTSP::AbstractStream)
      end

      def setup_rtp_sender(type)
        case type
        when :socat
          @rtp_sender = RTP::Sender.instance
          @rtp_sender.stream_module = RTP::Senders::Socat

          yield @rtp_sender if block_given?


=begin
      when :indirection
        # Get remote server's URL
        server_url = yield()

        # Get description from the remote RTSP server
        require_relative 'client'
        client = RTSP::Client.new(server_url)
        response = client.describe
        @description = response.body

        # Get the control URL for the main remote presentation and set that for
        # this URL
        control = @description.attributes.find { |a| a[:attribute] == "control" }
        self.url = control[:value]

        # Get the control URL for the first media section so we can get the
        # Stream object that was setup in configuration.
        media_control =
          @description.media_sections.first[:attributes].find { |a| a[:attribute] == "control" }
        redirected_stream = stream_at(media_control[:value])

        # Create a socket to redirect the RTP data that we'll start receiving.
        redirected_socket = UDPSocket.new
        redirected_socket.bind('0.0.0.0', redirected_stream.client_rtp_port)
        client.capturer.rtp_file = redirected_socket

        # Setup
        media_track = client.media_control_tracks.first
        aggregate_track = client.aggregate_control_track
        client.setup media_track
        client.play aggregate_track
=end
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
        sdp.session_section.add_field "a=control:*"

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
        if env['RTSP_ACCEPT'] &&
          env['RTSP_ACCEPT'].match(/application\/sdp/)
          content_type = 'application/sdp'
        else
          RTSP::Logger.log "Unknown Accept types: #{env['RTSP_ACCEPT']}", :warn
          return RTSP::Response.new(451).with_headers('CSeq' => env['RTSP_CSEQ'])
        end

        RTSP::Response.new(200).with_headers_and_body({
          'CSeq' => env['RTSP_CSEQ'],
          'Content-Type' => content_type,
          'Content-Base' => env['PATH_INFO'],
          body: @description.to_s
        })
      end

    end
  end
end
