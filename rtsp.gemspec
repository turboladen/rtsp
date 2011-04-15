# -*- encoding: utf-8 -*-
lib = File.expand_path('lib/', File.dirname(__FILE__))
$:.unshift lib unless $:.include?(lib)

require 'rtsp/version'

Gem::Specification.new do |s|
  s.name = "rtsp"
  s.version = RTSP::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ["Steve Loveless, Mike Kirby"]
  s.date = %q{2011-04-14}
  s.description = %q{This library intends to follow the RTSP RFC document (2326) to allow for working with RTSP servers.  At this point, it's up to you to parse the data from a play call, but we'll get there.  ...eventually.
For more information
RTSP: http://www.ietf.org/rfc/rfc2326.txt}
  s.email = ["steve.loveless@gmail.com, mkiby@gmail.com"]
  s.executables = ["rtsp_client"]
  s.extra_rdoc_files = [
    "ChangeLog.rdoc",
    "LICENSE.rdoc",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".infinity_test",
    ".rspec",
    ".yardopts",
    "ChangeLog.rdoc",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.rdoc",
    "README.rdoc",
    "Rakefile",
    "bin/rtsp_client",
    "features/client_changes_state.feature",
    "features/client_requests.feature",
    "features/control_streams_as_client.feature",
    "features/step_definitions/client_changes_state_steps.rb",
    "features/step_definitions/client_requests_steps.rb",
    "features/step_definitions/control_streams_as_client_steps.rb",
    "features/support/env.rb",
    "features/support/hooks.rb",
    "lib/ext/logger.rb",
    "lib/rtsp.rb",
    "lib/rtsp/capturer.rb",
    "lib/rtsp/client.rb",
    "lib/rtsp/error.rb",
    "lib/rtsp/global.rb",
    "lib/rtsp/helpers.rb",
    "lib/rtsp/message.rb",
    "lib/rtsp/response.rb",
    "lib/rtsp/transport_parser.rb",
    "lib/rtsp/version.rb",
    "rtsp.gemspec",
    "spec/.rspec",
    "spec/rtsp/client_spec.rb",
    "spec/rtsp/helpers_spec.rb",
    "spec/rtsp/message_spec.rb",
    "spec/rtsp/response_spec.rb",
    "spec/rtsp/transport_parser_spec.rb",
    "spec/rtsp_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/fake_rtsp_server.rb",
    "tasks/metrics.rake",
    "tasks/roodi_config.yml",
    "tasks/stats.rake"
  ]
  s.homepage = %q{http://rubygems.org/gems/rtsp}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rtsp}
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{Library to allow RTSP streaming from RTSP-enabled devices.}
  s.test_files = [
    "spec/rtsp_spec.rb",
    "spec/rtsp/client_spec.rb",
    "spec/rtsp/helpers_spec.rb",
    "spec/rtsp/message_spec.rb",
    "spec/rtsp/response_spec.rb",
    "spec/rtsp/transport_parser_spec.rb",
    "spec/rtsp_spec.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<code_statistics>, ["~> 0.2.13"])
      s.add_development_dependency(%q<metric_fu>, [">= 2.0.0"])
      s.add_development_dependency(%q<ore>, ["~> 0.7.2"])
      s.add_development_dependency(%q<ore-core>, ["~> 0.1.5"])
      s.add_development_dependency(%q<ore-tasks>, ["~> 0.5.0"])
      s.add_development_dependency(%q<rake>, ["~> 0.8.7"])
      s.add_development_dependency(%q<rspec>, ["~> 2.5.0"])
      s.add_development_dependency(%q<simplecov>, [">= 0.4.0"])
      s.add_development_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_runtime_dependency(%q<sdp>, ["~> 0.2.2"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<code_statistics>, ["~> 0.2.13"])
      s.add_dependency(%q<metric_fu>, [">= 2.0.0"])
      s.add_dependency(%q<ore>, ["~> 0.7.2"])
      s.add_dependency(%q<ore-core>, ["~> 0.1.5"])
      s.add_dependency(%q<ore-tasks>, ["~> 0.5.0"])
      s.add_dependency(%q<rake>, ["~> 0.8.7"])
      s.add_dependency(%q<rspec>, ["~> 2.5.0"])
      s.add_dependency(%q<simplecov>, [">= 0.4.0"])
      s.add_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_dependency(%q<sdp>, ["~> 0.2.2"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<code_statistics>, ["~> 0.2.13"])
    s.add_dependency(%q<metric_fu>, [">= 2.0.0"])
    s.add_dependency(%q<ore>, ["~> 0.7.2"])
    s.add_dependency(%q<ore-core>, ["~> 0.1.5"])
    s.add_dependency(%q<ore-tasks>, ["~> 0.5.0"])
    s.add_dependency(%q<rake>, ["~> 0.8.7"])
    s.add_dependency(%q<rspec>, ["~> 2.5.0"])
    s.add_dependency(%q<simplecov>, [">= 0.4.0"])
    s.add_dependency(%q<yard>, ["~> 0.6.0"])
    s.add_dependency(%q<sdp>, ["~> 0.2.2"])
  end
end

