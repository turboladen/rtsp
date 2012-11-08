require 'sys/proctable'
require_relative 'global'
require 'os'
require 'ipaddr'
require 'rtp/packet'

module RTSP
  module SocatStreaming
    include RTSP::Global

    RTCP_SOURCE = ["80c80006072dee6ad42c300f76c3b928377e99e5006c461ba92d8a3" +
      "081ca0006072dee6a010e49583330444e2d41414a4248513600000000"]
    MP4_RTP_MAP = "96 MP4V-ES/30000"
    MP4_FMTP = "96 profile-level-id=5;config=000001b005000001b50900000100000" +
      "0012000c888ba9860fa22c087828307"
    H264_RTP_MAP = "96 H264/90000"
    H264_FMTP = "96 packetization-mode=1;profile-level-id=428032;" +
      "sprop-parameter-sets=Z0KAMtoAgAMEwAQAAjKAAAr8gYAAAYhMAABMS0IvfjAA" +
      "ADEJgAAJiWhF78CA,aM48gA=="

    # @return [Hash] Hash of session IDs and SOCAT commands.
    attr_accessor :sessions

    # @return [Hash] Hash of session IDs and pids.
    attr_reader :pids

    # @return [Hash] Hash of session IDs and RTCP threads.
    attr_reader :rtcp_threads

    # @return [Array<String>] IP address of the source camera.
    attr_accessor :source_ip

    # @return [Array<Fixnum>] Port where the source camera is streaming.
    attr_accessor :source_port

    # @return [String] IP address of the interface of the RTSP streamer.
    attr_accessor :interface_ip

    # @return [Fixnum] RTP timestamp of the source stream.
    attr_accessor :rtp_timestamp

    # @return [Fixnum] RTP sequence number of the source stream.
    attr_accessor :rtp_sequence

    # @return [String] RTCP source identifier.
    attr_accessor :rtcp_source_identifier

    # @return [Array<String>] Media type attributes.
    attr_accessor :rtp_map

    # @return [Array<String>] Media format attributes.
    attr_accessor :fmtp

    # Generates a RTCP source ID based on the friendly name.
    # This ID is used in the RTCP communication with the client.
    # The default +RTCP_SOURCE+ will be used if one is not provided.
    #
    # @param [String] friendly_name Name to be used in the RTCP source ID.
    # @return [String] rtcp_source_id RTCP Source ID.
    def generate_rtcp_source_id friendly_name
      ["80c80006072dee6ad42c300f76c3b928377e99e5006c461ba92d8a3081ca0006072dee6a010e" +
        friendly_name.unpack("H*").first + "00000000"].pack("H*")
    end

    # Creates a RTP streamer using socat.
    #
    # @param [String] sid Session ID.
    # @param [String] transport_url Destination IP:port.
    # @param [Fixnum] index Stream index.
    # @return [Fixnum] The port the streamer will stream on.
    def setup_streamer(sid, transport_url, index=1)
      dest_ip, dest_port = transport_url.split ":"
      @rtcp_source_identifier ||= RTCP_SOURCE.pack("H*")
      local_port = free_port(true)

      @rtcp_threads[sid] = Thread.start do
        s = UDPSocket.new
        s.bind(@interface_ip, local_port+1)

        loop do
          begin
            _, sender = s.recvfrom(36)
            s.send(@rtcp_source_identifier, 0, sender[3], sender[1])
          end
        end
      end

      @cleaner ||= Thread.start { cleanup_defunct }
      @processes ||= Sys::ProcTable.ps.map { |p| p.cmdline }
      @sessions[sid] = build_socat(dest_ip, dest_port, local_port, index)

      local_port
    end

    SOCAT_OPTIONS = "rcvbuf=2500000,sndbuf=2500000,sndtimeo=0.00001,rcvtimeo=0.00001"
    BLOCK_SIZE = 2000
    BSD_OPTIONS = "setsockopt-int=0xffff:0x200:0x01"

    # Start streaming for the requested session.
    #
    # @param [String] session ID.
    def start_streaming sid
      spawn_socat(sid, @sessions[sid])
    end

    # Stop streaming for the requested session.
    #
    # @param [String] session ID.
    def stop_streaming sid
      if sid.nil?
        disconnect_all_streams
      else
        disconnect sid
        @rtcp_threads[sid].kill unless rtcp_threads[sid].nil?
        @rtcp_threads.delete sid
      end
    end

    # Returns the default stream description.
    #
    # @param[Boolean] multicast True if the description is for a multicast stream.
    # @param [Fixnum] stream_index Index of the stream type.
    def description multicast=false, stream_index=1
      rtp_map = @rtp_map[stream_index - 1] || H264_RTP_MAP
      fmtp = @fmtp[stream_index - 1] || H264_FMTP

      <<EOF
v=0\r
o=- 1345481255966282 1 IN IP4 #{@interface_ip}\r
s=Session streamed by "Streaming Server"\r
i=stream1\r
t=0 0\r
a=tool:LIVE555 Streaming Media v2007.07.09\r
a=type:broadcast\r
a=control:*\r
a=range:npt=0-\r
a=x-qt-text-nam:Session streamed by "Streaming Server"\r
a=x-qt-text-inf:stream1\r
m=video 0 RTP/AVP 96\r
c=IN IP4 #{multicast ? "#{multicast_ip(stream_index)}/10" : "0.0.0.0"}\r
a=rtpmap:#{rtp_map}\r
a=fmtp:#{fmtp}\r
a=control:track1\r
EOF
    end

    # Disconnects the stream matching the session ID.
    #
    # @param [String] sid Session ID.
    def disconnect sid
      pid = @pids[sid].to_i
      @pids.delete(sid)
      @sessions.delete(sid)
      Process.kill(9, pid) if pid > 1000
    rescue Errno::ESRCH
      log "Tried to kill dead process: #{pid}"
    end

    # Parses the headers from an RTP stream.
    #
    # @param [String] src_ip Multicast IP address of RTP stream.
    # @param [Fixnum] src_port Port of RTP stream.
    # @return [Array<Fixnum>] Sequence number and timestamp
    def parse_sequence_number(src_ip, src_port)
      sock = UDPSocket.new
      ip = IPAddr.new(src_ip).hton + IPAddr.new("0.0.0.0").hton
      sock.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip)
      sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
      sock.bind(Socket::INADDR_ANY, src_port)

      begin
        data = sock.recv_nonblock(1500)
      rescue Errno::EAGAIN
        retry
      end

      sock.close
      packet = RTP::Packet.read(data)

      [packet["sequence_number"], packet["timestamp"]]
    end

    private

    # Returns the multicast IP on which the streamer will stream.
    #
    # @param [Fixnum] index Stream index.
    # @return [String] Multicast IP.
    def multicast_ip index=1
      @interface_ip ||= find_best_interface_ipaddr @source_ip[index-1]
      multicast_ip = @interface_ip.split "."
      multicast_ip[0] = "239"

      multicast_ip.join "."
    end

    # Cleans up defunct child processes
    def cleanup_defunct
      loop do
        begin
          Process.wait 0
        rescue Errno::ECHILD
          sleep 10
          retry
        end
      end
    end

    # Determine the interface address that best matches an IP address. This
    # is most useful when talking to a remote computer and needing to
    # determine the interface that is being used for the connection.
    #
    # @param [String] device_ip IP address of the remote device you want to
    #   talk to.
    # @return [String] IP of the interface that would be used to talk to.
    def find_best_interface_ipaddr device_ip
      UDPSocket.open { |s| s.connect(device_ip, 1); s.addr.last }
    end

    # Disconnects all streams that are currently streaming.
    def disconnect_all_streams
      @pids.values.each { |pid| Process.kill(9, pid.to_i) if pid.to_i > 1000 }
      @sessions.clear
      @pids.clear
    end

    # Spawns an instance of Socat.
    #
    # @param [String] sid The session ID of the stream.
    # @param [String] command The SOCAT command to be spawned.
    def spawn_socat(sid, command)
      @processes ||= Sys::ProcTable.ps.map { |p| p.cmdline }

      if command.nil?
        log("SOCAT command for #{sid} was nil", :warn)
        return
      end

      if @processes.include?(command)
        pid = get_pid(command)
        log "Streamer already running with pid #{pid}" if pid.is_a? Fixnum
      else
        @sessions[sid] = command

        Thread.start do
          log "Running stream spawner: #{command}"
          @processes << command
          pid = spawn command
          @pids[sid] = pid
          Thread.start { sleep 20; spawn_socat(sid, command) }
        end
      end
    end

    # Builds a socat stream command based on the source and target
    # IP and ports of the RTP stream.
    #
    # @param [String] target_ip IP address of the remote device you want to
    # talk to.
    # @param [Fixnum] target_port Port on the remote device you want to
    # talk to.
    # @

    # @return [String] IP of the interface that would be used to talk to.
    def build_socat(target_ip, target_port, server_port, index=1)
      bsd_options = BSD_OPTIONS if OS.mac?
      bsd_options ||= ""

      "socat -b #{BLOCK_SIZE} UDP-RECV:#{@source_port[index-1]},reuseaddr," +
        "#{bsd_options}"+ SOCAT_OPTIONS + ",ip-add-membership=#{@source_ip[index-1]}:" +
        "#{@interface_ip} UDP:#{target_ip}:#{target_port},sourceport=#{server_port}," +
        SOCAT_OPTIONS
    end

    # Attempts to find a random bindable port between 50000-65500
    #
    # @param [Boolean] even Return a free even port number if true.
    # @return [Number] A random bindable port between 50000-65500
    # @raise [RuntimeError] When unable to locate port after 1000 attempts.
    def free_port(even=false)
      1000.times do
        begin
          port = rand(15500) + 50001
          port += 1 if port % 2 != 0 && even
          socket = UDPSocket.new
          socket.bind('', port)
          return port
        rescue
          # Do nothing if bind fails; continue looping
        ensure
          socket.close
        end
      end

      raise "Unable to locate free port after 1000 attempts."
    end


    # Gets the pid for a SOCAT command.
    #
    # @param [String] cmd SOCAT command
    # @return [Fixnum] PID of the process.
    def get_pid cmd
      Sys::ProcTable.ps.each do |p|
        return p.pid.to_i if p.cmdline.include? cmd
      end
    end
  end
end
