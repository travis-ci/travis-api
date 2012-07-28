require 'bundler/setup'
ENV['SCHEMA'] = "#{Gem.loaded_specs['travis-core'].full_gem_path}/db/schema.rb"

require 'micro_migrations'
require 'travis'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new
  task default: :spec
rescue LoadError
  warn "could not load rspec"
end
