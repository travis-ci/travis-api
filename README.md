# Travis API

[![Build Status](https://travis-ci.org/travis-ci/travis-api.svg?branch=master)](https://travis-ci.org/travis-ci/travis-api)

https://api.travis-ci.org

## Requirements

You will need the following packages to get travis-api to work:

1. PostgreSQL 9.3 or higher
2. Bundler
3. Redis Server
4. *Optional:* RabbitMQ Server
5. Nginx -
    *If working in Ubuntu please install nginx manually from source: Download and extract latest nginx version, open a terminal in extracted folder and then run the following:*
```sh-session
    $ sudo apt-get install libpcre3 libpcre3-dev
    $ auto/configure --user=$USER
    $ make
    $ sudo make install
    $ sudo ln -s /usr/local/nginx/sbin/nginx /bin/nginx
```

## Installation

### Setup
```sh-session
$ bundle install
```
### Main Database & Logs Database setup

*You might need to create a role first. For this you should run the following:*

```sh-session
$ sudo -u postgres psql -c "CREATE USER yourusername WITH SUPERUSER PASSWORD 'yourpassword'"
```

Databases are set up with a Rake task that uses the database schemas (`structure.sql`) in `travis-migrations` which is loaded as a Gem. Details can be found in the `Rakefile`.

If there have been new migrations added to `travis-migrations` since you bundle installed, you will need to update `travis-migrations` to ensure you have the latest version with the new migrations.

```sh-session
bundle update travis-migrations
```

To create and migrate the Databases:

```sh-session
$ RAILS_ENV=development bundle exec rake db:create
$ RAILS_ENV=test bundle exec rake db:create
```

Please Note: The database names are configured using the environment variable RAILS_ENV. If you are using a different configuration you will have to make your own adjustments.


### Run tests
```sh-session
$ bundle exec rake
```
### Run the server
```sh-session
$ bundle exec script/server
```
If you have problems with Nginx because the websocket is already in use, try restarting your computer.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### API documentation

v3 documentation can be found at https://developer.travis-ci.org which is a repository that can be found at https://github.com/travis-pro/developer

### Adding V3 Endpoints Developer Documentation
Start with the find/get spec (for example: spec/v3/services/caches/find_spec.rb) for your new endpoint. If you don't have a find route start with whatever route you want to add first. Run the test and add the files you need to clear the errors. They should be:
 - A service (lib/travis/api/v3/services/caches/find.rb)
 - A query (lib/travis/api/v3/queries/caches.rb)
 - Register the service in v3/services.rb (alphabetical order please)
 - Add a route (v3/routes.rb)
 Re-run the test at this point. Depending on what objects you are returning you may also need to add:
 - Add a model (either pulls from the DB or a wrapper for the class of the objects returned from another source (s3 for example), or that structures the result you will be passing back to the client)
 - Add a renderer (if needed to display your new model/object/collection)
