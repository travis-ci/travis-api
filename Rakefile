namespace :db do
  if ENV["RAILS_ENV"] == 'test'
    desc 'Create and migrate the test database'
    task :create do
      sh 'createdb travis_test' rescue nil
      sh "psql -q travis_test < #{Gem.loaded_specs['travis-migrations'].full_gem_path}/db/structure.sql"
    end
  else
    desc 'Create and migrate the development database'
    task :create do
      sh 'createdb travis_development' rescue nil
      sh "psql -q travis_development < #{Gem.loaded_specs['travis-migrations'].full_gem_path}/db/structure.sql"
    end
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

## can this be removed? what other rakefiles need to be included?
# tasks_path = File.expand_path('../lib/tasks/*.rake', __FILE__)
# Dir.glob(tasks_path).each { |r| import r }
