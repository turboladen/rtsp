# -*- encoding: utf-8 -*-

begin
  Ore::Specification.new do |gemspec|
    gemspec.test_files = Dir.glob("spec/**/*.rb")
    gemspec.post_install_message = File.readlines('PostInstall.txt')
  end
rescue NameError
  begin
    require 'ore/specification'
    retry
  rescue LoadError
    STDERR.puts "The 'rtsp.gemspec' file requires Ore."
    STDERR.puts "Run `gem install ore-core` to install Ore."
  end
end
