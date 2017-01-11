namespace :db do
  env = ENV["RAILS_ENV"] || 'development'
  if env != 'production'
    desc "Create and migrate the #{env} database"
    task :create do
      sh "createdb travis_#{env}" rescue nil
      sh "psql -q travis_#{env} < #{Gem.loaded_specs['travis-migrations'].full_gem_path}/db/main/structure.sql"

      sh "createdb travis_logs_#{env}" rescue nil
      sh "psql -q travis_logs_#{env} < #{Gem.loaded_specs['travis-migrations'].full_gem_path}/db/logs/structure.sql"
    end
  end
end

namespace :spec do
  desc 'Run all specs'
  task :all do
    sh 'bundle exec rspec -r spec_helper spec'
  end
end

task :default => :'spec:all'
