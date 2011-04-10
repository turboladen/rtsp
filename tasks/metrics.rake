require 'metric_fu'

MetricFu::Configuration.run do |config|
  #define which metrics you want to use
  #config.metrics  = [:churn, :flog, :flay, :reek, :roodi, :rcov, :stats]
  config.metrics  = [:churn, :flay, :reek, :roodi, :rcov, :stats]
  #config.graphs   = [:flog, :flay, :reek, :roodi, :rcov, :stats]
  config.graphs   = [:flay, :reek, :roodi, :rcov, :stats]
  config.churn    = { :start_date => "1 year ago", :minimum_churn_count => 10 }
  config.flay     = { :dirs_to_flay => ['lib'],
                      :minimum_score => 10,
                      :filetypes => ['rb', 'erb'] }
  config.flog     = { :dirs_to_flog => ['lib'] }
  config.rcov     = { :environment => 'test',
                      :test_files => ["spec/**/*_spec.rb"],
                      :rcov_opts => ["--sort coverage",
                                     "--no-html",
                                     "--text-coverage",
                                     "--spec-only",
                                     "--no-color",
                                     "--profile",
                                     "--exclude /gems/,/Library/"]
                    }
  config.reek     = { :dirs_to_reek => ['lib'] }
  config.roodi    = { :dirs_to_roodi => ['lib'], :roodi_config => "tasks/roodi_config.yml" }
  config.graph_engine = :bluff
end
