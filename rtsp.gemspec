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
  s.description = %q{This library intends to follow the RTSP RFC document (2326)
to allow for working with RTSP servers.  At this point, it's up to you to parse
the data from a play call, but we'll get there.  ...eventually.
For more information see: http://www.ietf.org/rfc/rfc2326.txt}
  s.email = ["steve.loveless@gmail.com, mkiby@gmail.com"]
  s.executables = ["rtsp_client"]
  s.extra_rdoc_files = [
    "ChangeLog.rdoc",
      "LICENSE.rdoc",
      "README.rdoc"
  ]
  s.files = Dir.glob("{lib,bin,tasks}/**/*") +
    %w(.gemtest rtsp.gemspec) +
    %w(Gemfile ChangeLog.rdoc LICENSE.rdoc README.rdoc Rakefile)
  s.homepage = %q{http://rubygems.org/gems/rtsp}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rtsp}
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{Library to allow RTSP streaming from RTSP-enabled devices.}
  s.test_files = Dir.glob("{spec,features}/**/*")

  s.add_runtime_dependency(%q<sdp>, ["~> 0.2.2"])

  s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
  s.add_development_dependency(%q<code_statistics>, ["~> 0.2.13"])
  s.add_development_dependency(%q<metric_fu>, [">= 2.0.0"])
  s.add_development_dependency(%q<rspec>, [">= 2.5.0"])
  s.add_development_dependency(%q<simplecov>, [">= 0.4.0"])
  s.add_development_dependency(%q<yard>, [">= 0.6.0"])
end
