namespace :db do
  env = ENV["ENV"] || 'test'
  abort "Cannot run rake db:create in production." if env == 'production'

  url   = "https://raw.githubusercontent.com/travis-ci/travis-migrations/master/db/main/structure.sql"
  file  = 'db/structure.sql'
  system "curl -fs #{url} -o #{file} --create-dirs"
  abort "failed to download #{url}" unless File.exist?(file)

  desc "Create and migrate the #{env} database"
  task :create do
    sh "createdb travis_#{env}" rescue nil
    sh "psql -q travis_#{env} < #{file}"
  end
end

namespace :spec do
  desc 'Run all specs'
  task :all do
    sh 'bundle exec rspec -r spec_helper spec'
  end
end

task :default => :'spec:all'
