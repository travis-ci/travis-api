# The public Travis API

This is the app running on https://api.travis-ci.org/

## Requirements

1. PostgreSQL 9.3 or higher
1. Redis
1. RabbitMQ

## Installation

### Setup

    $ bundle install

### Database setup

1. `rake db:create db:structure:load`
1. Clone `travis-logs` and copy the `logs` database (assume the PostgreSQL user is `postgres`):
```sh-session
cd ..
git clone https://github.com/travis-ci/travis-logs.git
cd travis-logs
rvm jruby do bundle exec rake db:migrate # `travis-logs` requires JRuby
psql -c "DROP TABLE IF EXISTS logs CASCADE" -U postgres travis_development
pg_dump -t logs travis_logs_development | psql -U postgres travis_development
```

Repeat the database steps for `RAILS_ENV=test`.
```sh-session
RAILS_ENV=test rake db:create db:structure:load
pushd ../travis-logs
RAILS_ENV=test rvm jruby do bundle exec rake db:migrate
psql -c "DROP TABLE IF EXISTS logs CASCADE" -U postgres travis_test
pg_dump -t logs travis_logs_test | psql -U postgres travis_test
popd
```


### Run tests

    $ rake spec

### Run the server

    $ bundle exec script/server

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### API documentation

We use source code comments to add documentation. If the server is running, you
can browse an HTML documenation at [`/docs`](http://localhost:5000/docs).

### Project architecture

    lib
    `-- travis
        `-- api
            `-- app
                |-- endpoint    # API endpoints
                |-- extensions  # Sinatra extensions
                |-- helpers     # Sinatra helpers
                `-- middleware  # Rack middleware

Classes inheriting from `Endpoint` or `Middleware`, they will automatically be
set up properly.

Each endpoint class gets mapped to a prefix, which defaults to the snake-case
class name (i.e. `Travis::Api::App::Profile` will map to `/profile`).
It can be overridden by setting `:prefix`:

``` ruby
require 'travis/api/app'

class Travis::Api::App
  class MyRouts < Endpoint
    set :prefix, '/awesome'
  end
end
```
