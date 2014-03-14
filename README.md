# The public Travis API

This is the app running on https://api.travis-ci.org/

## Installation

Setup:

    $ bundle install

Run tests:

    $ RAILS_ENV=test rake db:create db:structure:load
    $ rake spec

Run the server:

    $ rake db:create db:structure:load
    $ script/server

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
