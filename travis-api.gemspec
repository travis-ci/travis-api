# encoding: utf-8

Gem::Specification.new do |s|
  s.description  = 'The Travis API'
  s.summary      = 'Code running on http://api.travis-ci.org'
  s.name         = 'travis-api'
  s.homepage     = 'http://api.travis-ci.org'
  s.version      = '0.0.1'
  s.require_path = 'lib'
  s.authors      = ['Travis CI and others']
  s.email        = ['contact@travis-ci.org']

  s.add_dependency 'travis-support'
  s.add_dependency 'composite_primary_keys', '~> 9.0'
  s.add_dependency 'pg',                     '~> 0.21'
  s.add_dependency 'sinatra',                '~> 1.3'
  s.add_dependency 'sinatra-contrib',        '~> 1.3'
  s.add_dependency 'mustermann',             '~> 1.0.0.beta2'
  s.add_dependency 'redcarpet',              '>= 3.2.3'
  s.add_dependency 'rack-ssl',               '~> 1.3', '>= 1.3.3'
  s.add_dependency 'rack-contrib',           '~> 1.1'
  s.add_dependency 'memcachier'
  s.add_dependency 'useragent'
  s.add_dependency 'tool'
  s.add_dependency 'google-api-client', '~> 0.9.4'
  s.add_dependency 'fog-aws',           '~> 0.12.0'
  s.add_dependency 'fog-google',        '~> 0.4.2'

  # from travis-core gemspec

  s.add_dependency 'activerecord',      '~> 5.0'
  s.add_dependency 'rollout',           '~> 1.1.0'
  s.add_dependency 'coder',             '~> 0.4.0'
  s.add_dependency 'virtus',            '~> 1.0.0'
  s.add_dependency 'redis',             '~> 3.0'
  s.add_dependency 'hashr'
  s.add_dependency 'simple_states'
  s.add_dependency 'pusher',            '~> 0.14.0'
  s.add_dependency 'multi_json'
end
