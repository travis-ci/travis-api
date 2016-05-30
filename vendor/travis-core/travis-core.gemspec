# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'travis_core/version'

Gem::Specification.new do |s|
  s.name         = "travis-core"
  s.version      = TravisCore::VERSION
  s.authors      = ["Travis CI"]
  s.email        = "contact@travis-ci.org"
  s.homepage     = "https://github.com/travis-ci/travis-core"
  s.summary      = "The heart of Travis"

  s.files        = Dir['{lib/**/*,spec/**/*,[A-Z]*}']
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'

  s.add_dependency 'rake'
  s.add_dependency 'thor'
  s.add_dependency 'activerecord',      '~> 3.2.19'
  s.add_dependency 'actionmailer',      '~> 3.2.19'
  s.add_dependency 'railties',          '~> 3.2.19'
  s.add_dependency 'rollout',           '~> 1.1.0'
  s.add_dependency 'coder',             '~> 0.4.0'
  s.add_dependency 'virtus',            '~> 1.0.0'

  # travis
  s.add_dependency 'travis-config',     '~> 0.1.0'

  # db
  s.add_dependency 'data_migrations',   '~> 0.0.1'
  s.add_dependency 'redis',             '~> 3.0'


  # structures
  s.add_dependency 'hashr'
  s.add_dependency 'metriks',           '~> 0.9.7'

  # app
  s.add_dependency 'simple_states',     '~> 1.0.0'

  # apis
  s.add_dependency 'pusher',            '~> 0.14.0'
  s.add_dependency 's3',                '~> 0.3'
  s.add_dependency 'gh'
  s.add_dependency 'multi_json'
  s.add_dependency 'google-api-client', '~> 0.9.4'
end
