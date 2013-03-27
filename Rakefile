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
