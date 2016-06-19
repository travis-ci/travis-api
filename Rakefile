namespace :db do
  env = ENV["RAILS_ENV"]
  if env != 'production'
    desc "Create and migrate the #{env} database"
    task :create do
      sh "createdb travis_#{env}" rescue nil
      sh "psql -q travis_#{env} < #{Gem.loaded_specs['travis-migrations'].full_gem_path}/db/structure.sql"
    end
  end
end

# begin
#   require 'rspec'
#   require 'rspec/core/rake_task'
#   RSpec::Core::RakeTask.new(:spec)
#
#   RSpec::Core::RakeTask.new(:spec_core) do |t|
#     t.pattern = 'spec_core/**{,/*/**}/*_spec.rb'
#   end
#
#   task :default => [:spec, :spec_core]
# rescue LoadError => e
#   puts e.inspect
# end

# not sure how else to include the spec_helper
namespace :spec do
  desc 'Run all specs'
  task :all do
    sh 'bundle exec rspec -r spec_helper spec spec_core'
  end

  desc 'Run api specs'
  task :api do
    sh 'bundle exec rspec -r spec_helper spec'
  end

  desc 'Run core specs'
  task :core do
    sh 'bundle exec rspec -r spec_helper spec_core'
  end
end

task :default => :'spec:all'
