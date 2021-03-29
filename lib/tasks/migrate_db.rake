ActiveRecord::Base.schema_format = :sql

task('db:structure:load' => :copy_structure)

task(:copy_structure) do
  require 'fileutils'
  if branch = ENV['TRAVIS_MIGRATIONS_BRANCH'] and !branch.empty?
    $stderr.puts 'Warning: travis-migrations branch overridden by environment variable.'
  else
    branch = 'master'
  end
  url   = "https://raw.githubusercontent.com/travis-ci/travis-migrations/#{branch}/db/main/structure.sql"
  file  = 'db/structure.sql'
  FileUtils.mkdir_p('db')
  puts url
  system "curl -fs #{url} -o #{file} --create-dirs"
  abort "failed to download #{url}" unless File.exist?(file)
end
