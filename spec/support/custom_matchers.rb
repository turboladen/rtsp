require 'rspec/expectations'

RSpec::Matchers.define :be_ok do
  match do |actual_response|
    @fail_types = []

    @fail_types << "class" unless actual_response.is_a?(RTSP::Response)
    @fail_types << "code" unless actual_response.code == 200
    @fail_types << "message" unless actual_response.status_message == 'OK'
    @fail_types << "rtsp_version" unless actual_response.rtsp_version == '1.0'

    @fail_types.empty?
  end

  failure_message_for_should do |actual_response|
    msgs = []

    if @fail_types.include? "class"
      msgs << "Response was a #{actual_response.class} but should be a RTSP::Response"
    end

    if @fail_types.include? "code"
      msgs << "Response code was #{actual_response.code} but should be '200'"
    end

    if @fail_types.include? "message"
      msgs << "Response message was #{actual_response.message} but should be 'OK'"
    end

    if @fail_types.include? "rtsp_version"
      msgs << "Response rtsp_version was #{actual_response.rtsp_version} but should be '1.0'"
    end

    msgs.join("\n")
  end
end
