# -*- ruby -*-

require 'hoe'
require 'yard'
require './lib/rtsp_client'

Hoe.plugin :newgem
Hoe.plugin :yard
Hoe.plugin :cucumberfeatures
Hoe.plugins.delete :rubyforge

# Gets the description from the README file
def get_descr_from_readme
  paragraph_count = 0
  File.readlines('README.textile', '').each do |paragraph|
    paragraph_count += 1
    if paragraph_count == 2
      return paragraph
    end
  end
end


# The main Gemspec definition
Hoe.spec 'rtsp_client' do
  self.summary        = 'FIX'
  self.developer('FIX', 'FIX@example.com')
  self.post_install_message = File.readlines 'PostInstall.txt'
  self.version        = RtspClient::VERSION
  self.url            = RtspClient::RtspClient_WWW
  self.description    = get_descr_from_readme
  self.readme_file    = 'README.textile'
  self.history_file   = 'History.textile'
  self.rspec_options  += ['--color', '--format', 'specdoc']
  self.extra_deps     += [
      '']
  ]
  self.extra_dev_deps += [
      ['rspec'],
      ['yard', '>=0.5.3'],
      ['cucumber', '>=0.6.3'],
      ['hoe-yard', '>=0.1.2']
  ]

  self.spec_extras[:required_ruby_version] = '>=1.9.1'
  self.test_globs = 'spec/*.rb'

  # Extra Yard options
  self.yard_title = "#{self.name} Documentation (#{self.version})"
  self.yard_markup = "textile"
  self.yard_opts += ['--main', self.readme_file]
  self.yard_opts += ['--output-dir', 'doc']
  self.yard_opts += ['--private']
  self.yard_opts += ['--protected']
  self.yard_opts += ['--verbose']
  self.yard_opts += ['--files', 
      ['History.textile', 'Manifest.txt', self.readme_file]
  ]
end


#-------------------------------------------------------------------------------
# Overwrite the :clobber_docs Rake task so that it doesn't destroy our docs
#   directory.
#-------------------------------------------------------------------------------
class Rake::Task
  def overwrite(&block)
    @actions.clear
    enhance(&block)
  end
end

Rake::Task[:clobber_docs].overwrite do
end

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]

# vim: syntax=ruby
