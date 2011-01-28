require 'rubygems' if RUBY_VERSION < "1.9.0"
require 'hoe'
require 'hoe/yard'
require 'yard'
require 'newgem/tasks'
require 'bundler/setup'
require File.expand_path(File.dirname(__FILE__)) + '/lib/rtsp'

Hoe.plugin :newgem
Hoe.plugin :yard
Hoe.plugin :cucumberfeatures
Hoe.plugins.delete :rubyforge

# Gets the description from the README file
def get_descr_from_readme
  paragraph_count = 0

  File.readlines('README.rdoc', '').each do |paragraph|
    paragraph_count += 1

    return paragraph if paragraph_count == 2
  end
end

# The main Gemspec definition
Hoe.spec 'rtsp' do
  self.summary        = 'Library to allow RTSP streaming from RTSP-enabled devices.'
  self.developer('Steve Loveless & Mike Kirby', 'steve.loveless@gmail.com, mkirby@gmail.com')
  self.post_install_message = File.readlines 'PostInstall.txt'
  self.version        = RTSP::VERSION
  self.url            = RTSP::WWW
  self.description    = get_descr_from_readme
  self.readme_file    = 'README.rdoc'
  self.history_file   = 'History.txt'
  self.rspec_options  += ['--color', '--format', 'documentation']
  self.extra_deps     += [
      ['sdp', '~>0.2.0']
  ]
  self.extra_dev_deps += [
      ['rspec', ">=2.0.1"],
      ['yard', '>=0.6.4'],
      ['cucumber'],
      ['hoe-yard', '>=0.1.2']
  ]

  self.test_globs = 'spec/*.rb'

  # Extra Yard options
  self.yard_title = "#{self.name} Documentation (#{self.version})"
  self.yard_opts += ['--output-dir', 'doc']
  self.yard_opts += ['--private']
  self.yard_opts += ['--protected']
  self.yard_opts += ['--verbose']
  self.yard_opts += ['--files', 
      [self.history_file, 'Manifest.txt', self.readme_file]
  ]
end
