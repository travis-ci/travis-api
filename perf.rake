namespace :perf do
  task :rack_load do
    require 'travis/api/app'
    DERAILED_APP = Travis::Api::App.new
  end
end
