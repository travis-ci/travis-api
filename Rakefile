require 'rake'
require 'travis/migrations'

task default: :spec

namespace :db do
  desc 'Create the test database'
  task :create do
    sh 'createdb travis_test' rescue nil
    sh 'mkdir spec/support/db'
    sh "cp #{Gem.loaded_specs['travis-migrations'].full_gem_path}/db/structure.sql spec/support/db/structure.sql"
    sh 'psql -q travis_test < spec/support/db/structure.sql'
  end
end

desc "generate gemspec"
task 'travis-api.gemspec' do
   content = File.read 'travis-api.gemspec'

   fields = {
     authors: `git shortlog -sn`.scan(/[^\d\s].*/),
     email:   `git shortlog -sne`.scan(/[^<]+@[^>]+/),
     files:   `git ls-files`.split("\n").reject { |f| f =~ /^(\.|Gemfile)/ }
   }

   fields.each do |field, values|
     updated = "  s.#{field} = ["
     updated << values.map { |v| "\n    %p" % v }.join(',')
     updated << "\n  ]"
     content.sub!(/  s\.#{field} = \[\n(    .*\n)*  \]/, updated)
   end

   File.open('travis-api.gemspec', 'w') { |f| f << content }
 end

 task default: 'travis-api.gemspec'

 tasks_path = File.expand_path('../lib/tasks/*.rake', __FILE__)
 Dir.glob(tasks_path).each { |r| import r }
