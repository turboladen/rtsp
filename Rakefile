require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ['--format', 'documentation', '--color']
end

namespace :spec do
  RSpec::Core::RakeTask.new(:warnings) do |t|
    t.ruby_opts = "-w"
    t.rspec_opts = ['--format', 'documentation', '--color']
  end
end
task :default => :spec
task :test => :spec       # for `gem test`

YARD::Rake::YardocTask.new do |t|
  t.options = ['--verbose']
end

# Load all extra rake tasks
Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].each { |ext| load ext }
