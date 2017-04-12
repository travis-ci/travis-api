# Travis Admin 2.0

## Description
Travis Admin is an application used for viewing and managing Travis accounts and their builds. Additional high-level description to come soon.

## What It Can Do
This is where we will document the features and abilities that admin has. Example for the previous admin is on [the old readme](https://github.com/travis-pro/travis-admin#things-it-can-do).

## Status
Travis Admin (2.0) was build by the Emerald Project team June-November 2016. It falls under Team Sapphire's areas of responsibility.

## Local Setup

### Install dependencies

```
bundle install
```

### Setup the database for development/test

Go to [travis-migrations](https://github.com/travis-ci/travis-migrations) and follow the instructions there.

### Make a `config/travis.yml`

`Rakefile` defines the task `config[:env, :pro]`, which writes configuration file to `config/travis.yml`.
This task assumes that: a sibling directories `travis-keychain` and `travis-pro-keychain` exist and are
up to date, and that [trvs](https://githbu.com/travis-pro/trvs) is properly configured and functional.

The `rake` task also writes two `export` commands at the end, which is useful for running the Rails server:

```
$ rake config["staging","pro"]
I, [2017-03-20T19:04:57.958573 #89131]  INFO -- : writing to config/travis.yml
export GITHUB_LOGIN=YOUR_OWN_GITHUB_LOGIN
export STAGING_DATABASE_URL=`heroku config:get DATABASE_URL -a travis-pro-staging`
```

`zsh` may have issues with Rake task taking `[]` as a part of an argument. If it does, run with
`noglob` precommand modifier:

```
$ noglob rake config["staging","pro"]
```

#### Manually generating `config/travis.yml`

Instead of using the Rake task, you can manually generate the configuration file by following these steps.

First, fetch

`trvs generate-config --pro admin staging  > config/travis.yml`

Manually add "development:" as a parent, nest the updated config info under that, and remove the config for redis (so that we use our local redis instance). Also make sure to remove travis_config=--- if it is at the top of the file.

##### Disabling OTP (One-Time Password)

You can disable one time password in development by adding `disable_otp: true` to your `config/travis.yml`.

### Use Staging database in development

After generating `config/travis.yml`, export two environment variables:

```sh-session
export GITHUB_LOGIN=YOUR_OWN_GITHUB_LOGIN # replace YOUR_OWN_GITHUB_LOGIN with the real GitHub user name
export STAGING_DATABASE_URL=`heroku config:get DATABASE_URL -a travis-pro-staging`
```

Then start the rails server
1. `rails s`
2. Go to http://localhost:3000

### Running tests locally

The `test` environment needs to be defined in `config/travis.yml`.
The easiest way to achieve this is to concatenate `config/travis.example.yml` to
`config/travis.yml`:

```sh-session
$ cat config/travis.example.yml >> config/travis.yml
```

Run `RAILS_ENV=test bundle exec rake db:drop db:create db:structure:load spec`

## How to Deploy

At the moment we deploy by pushing to heroku:

`git push heroku master` or `git push heroku <branch-name>:master`
