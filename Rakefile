require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new

namespace :spec do
  RSpec::Core::RakeTask.new(:warnings) do |t|
    t.ruby_opts = '-w'
  end
end
task :default => :spec
task :test => :spec       # for `gem test`

YARD::Rake::YardocTask.new do |t|
  t.files = %w(lib/**/*.rb - ChangeLog.rdoc)
  t.options = %w[--verbose]
end
