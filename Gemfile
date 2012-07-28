source :rubygems
ruby '1.9.3' rescue nil

gem 'travis-support', github: 'travis-ci/travis-support'
gem 'travis-core',    github: 'travis-ci/travis-core'
gem 'hubble',         github: 'roidrage/hubble'

gem 'backports',    '~> 2.5'
gem 'pg',           '~> 0.13.2'
gem 'newrelic_rpm', '~> 3.3.0'
gem 'thin',         '~> 1.4'
gem 'sinatra'
gem 'sinatra-contrib'
gem 'redcarpet'

group :production do
  gem 'rack-ssl'
end

group :test do
  gem 'rspec',        '~> 2.11'
  gem 'factory_girl', '~> 2.4.0'
end

group :development do
  gem 'yard-sinatra', github: 'rkh/yard-sinatra'
  gem 'foreman'
  gem 'rerun'
end

group :development, :test do
  gem 'rake', '~> 0.9.2'
  gem 'micro_migrations', git: 'git://gist.github.com/2087829.git'
end
