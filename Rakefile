namespace :db do
  env = ENV["RAILS_ENV"]
  if env != 'production'
    desc "Create and migrate the #{env} database"
    task :create do
      sh "createdb travis_#{env}" rescue nil
      sh "psql -q travis_#{env} < #{Gem.loaded_specs['travis-migrations'].full_gem_path}/db/structure.sql"

      # logs database
      require 'sequel'
      Sequel.extension(:migration)
      db = Sequel.connect(:adapter => 'postgres', :database => "travis_#{env}")
      db.timezone = :utc
      Sequel::Migrator.run(db, Gem.loaded_specs['travis-migrations'].full_gem_path + '/db/migrate_logs', :table => 'schema_migrations_logs')
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
#   task :default => [:spec]
# rescue LoadError => e
#   puts e.inspect
# end

# not sure how else to include the spec_helper
namespace :spec do
  desc 'Run all specs'
  task :all do
    sh 'bundle exec rspec -r spec_helper spec'
  end
end

task :default => :'spec:all'
