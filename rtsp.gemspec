# -*- encoding: utf-8 -*-
lib = File.expand_path('lib/', File.dirname(__FILE__))
$:.unshift lib unless $:.include?(lib)

require 'rtsp/version'

Gem::Specification.new do |s|
  s.name = "rtsp"
  s.version = RTSP::VERSION

  s.homepage = %q{https://github.com/turboladen/rtsp}
  s.authors = ["Steve Loveless, Mike Kirby", "Sujin Philip"]
  s.summary = %q{Library to allow RTSP streaming from RTSP-enabled devices.}
  s.description = %q{This library intends to follow the RTSP RFC document (2326)
to allow for working with RTSP servers.  At this point, it's up to you to parse
the data from a play call, but we'll get there.  ...eventually.
For more information see: http://www.ietf.org/rfc/rfc2326.txt}
  s.email = %w{steve.loveless@gmail.com}
  s.licenses = %w{MIT}

  s.executables = %w{rtsp_client}
  s.files = Dir.glob("{lib,bin,spec,tasks}/**/*") + Dir.glob("*.rdoc") +
    %w(.gemtest rtsp.gemspec Gemfile Rakefile)
  s.extra_rdoc_files = %w{ChangeLog.rdoc LICENSE.rdoc README.rdoc}
  s.require_paths = %w{lib}
  s.rubygems_version = %q{1.7.2}
  s.test_files = Dir.glob("{spec,features}/**/*")

  s.add_runtime_dependency(%q<parslet>, [">= 1.1.0"])
  s.add_runtime_dependency(%q<rtp>, [">= 0.0.1"])
  s.add_runtime_dependency(%q<sdp>, ["~> 0.2.6"])
  s.add_runtime_dependency(%q<sys-proctable>, ["> 0"])

  s.add_development_dependency(%q<bundler>)
  s.add_development_dependency(%q<code_statistics>, ["~> 0.2.13"])
  s.add_development_dependency(%q<cucumber>, [">= 1.1.0"])
  s.add_development_dependency(%q<roodi>, [">= 2.1.0"])
  s.add_development_dependency(%q<rake>, [">= 0.8.7"])
  s.add_development_dependency(%q<rspec>, [">= 2.5.0"])
  s.add_development_dependency(%q<simplecov>, [">= 0.4.0"])
  s.add_development_dependency(%q<yard>, [">= 0.6.0"])
end
