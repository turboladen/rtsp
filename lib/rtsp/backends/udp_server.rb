# Listens on the UDP socket for RTSP requests.
=begin
    def udp_listen
      log "Starting UDP RTSP request listener..."

      loop do
        data, sender = @udp_server.recvfrom(500)
        remote_address = sender[3]
        remote_port = sender[1]
        log "UDP listener received data:\n#{data}"
        log "...from #{remote_address}:#{remote_port}"

        #response = process_request(data, sender[3])
        request = RTSP::Request.parse(data)
        log "Parsed request: #{request}"
        #@agent[remote_address] = request.headers[:user_agent]

        @sessions[remote_address] ||= Struct::Session.new
        @sessions[remote_address].user_agent ||= request.headers[:user_agent]
        @sessions[remote_address].cseq = request.headers[:cseq]
        @sessions[remote_address].remote_address = remote_address
        @sessions[remote_address].remote_port = remote_port

        #response = RTSP::Response.send(request.action)
        #@udp_server.send(response.to_s, 0, sender[3], sender[1])
        respond_to(request.method_type, @sessions[remote_address], request)
      end
    end

    # Serves a client request.
    #
    # @param [IO] io Request/response socket object.
    def serve io
      request_str = ""
      count = 0

      begin
        request_str << io.read_nonblock(500)
      rescue Errno::EAGAIN
        return -1 if count > 50
        count += 1
        sleep 0.01
        retry
      end

      #response = process_request(request_str, io)
      #io.send(response, 0)

      log "TCP listener received data:"
      request_str.each_line { |line| log "<<< #{line}" }

      request = RTSP::Request.parse(request_str)

      remote_ip, remote_port = peer_info(io)
      @sessions[io] ||= Struct::Session.new
      @sessions[io].user_agent ||= request.headers[:user_agent]
      @sessions[io].cseq = request.headers[:cseq]
      @sessions[io].remote_address = remote_ip
      @sessions[io].remote_port = remote_port

      respond_to_tcp(request.method_type, @sessions[io], request, io)
    end

    def peer_info(io)
      io.getpeername
      peer_bytes = io.getpeername[2, 6].unpack("nC4")
      port = peer_bytes.first.to_i
      ip = peer_bytes[1, 4].join(".")

      [ip, port]
    end

    # @param [Symbol] method_type
    # @param [Struct::Session] session
    # @param [RTSP::Request] request
    def respond_to(method_type, session, request)
      response = self.send(method_type, session, request)

      log "Sending UDP response:\n#{response}"
      @udp_server.send(response.to_s, 0, session.remote_address, session.remote_port)
    end
    def respond_to_tcp(method_type, session, request, io)
      response = self.send(method_type, session, request)

      log "Sending TCP response:"
      response.each_line { |line| log ">>> #{line}" }

      io.send(response.to_s, 0)
    end

    # Process an RTSP request
    #
    # @param [String] request_str RTSP request.
    # @param [String] remote_address IP address of sender.
    # @return [String] Response.
=begin

    def process_request(request_str, io)
      remote_address = io.remote_address.ip_address
      /(?<action>.*) rtsp:\/\// =~ request_str
      request = RTSP::Request.new(request_str, remote_address)
      @agent[io] = request.user_agent
      response, body = send(action.downcase.to_sym, request)

      add_headers(request, response, body)
    end

=end
