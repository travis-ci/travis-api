ruby '1.9.3' rescue nil

source :rubygems
gemspec

gem 'travis-support', github: 'travis-ci/travis-support'
gem 'travis-core',    github: 'travis-ci/travis-core', branch: 'sf-travis-api'
gem 'hubble',         github: 'roidrage/hubble'
gem 'yard-sinatra',   github: 'rkh/yard-sinatra'
gem 'rack-contrib',   github: 'rack/rack-contrib'
gem 'gh',             github: 'rkh/gh'
gem 'bunny'

group :test do
  gem 'rspec',        '~> 2.11'
  gem 'factory_girl', '~> 2.4.0'
  gem 'mocha',        '~> 0.12'
  gem 'database_cleaner', '~> 0.8.0'
end

group :development do
  gem 'foreman'
  gem 'rerun'
end

group :development, :test do
  gem 'rake', '~> 0.9.2'
  gem 'micro_migrations', git: 'git://gist.github.com/2087829.git'
end
