namespace :db do
  env = ENV["ENV"] || 'test'
  concurrency = ENV["CONCURRENCY"] || 2

  abort "Cannot run rake db:create in production." if env == 'production'

  if branch = ENV['TRAVIS_MIGRATIONS_BRANCH'] and !branch.empty?
    $stderr.puts "Warning: travis-migrations branch overridden by environment variable."
  else
    branch = 'master'
  end

  url   = "https://raw.githubusercontent.com/travis-ci/travis-migrations/#{branch}/db/main/structure.sql"
  file  = 'db/structure.sql'
  puts url
  system "curl -fs #{url} -o #{file} --create-dirs"
  abort "failed to download #{url}" unless File.exist?(file)

  desc "Create and migrate the #{env} database"
  task :create do
    sh "createdb travis_#{env}" rescue nil
    sh "psql -q travis_#{env} < #{file}"
  end

  namespace :prepare do
    task :parallel do
      concurrency.to_i.times do |i|
        sh "createdb travis_#{env}#{i}" rescue nil
        sh "psql -q travis_#{env}#{i} < #{file}"
      end
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