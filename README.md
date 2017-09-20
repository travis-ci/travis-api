# Travis Admin 2.0

## Description
Travis Admin is an application for administrating the Travis system.

## Status
Travis Admin (2.0) was build by the Emerald Project team June-November 2016. It falls under Team Jade's areas of responsibility.

## Local Setup

### Install dependencies

```
bundle install
```

## Generating `config/travis.yml`

### Development config

`trvs generate-config --pro admin staging  > config/travis.yml`

Manually add "development:" as a parent, nest the updated config info under that, and remove the config for redis (so that we use our local redis instance). Also make sure to remove travis_config=--- if it is at the top of the file.

### Test config

```sh-session
$ cat config/travis.test.yml >> config/travis.yml
```

### Disabling OTP (One-Time Password)

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

Run this command once to create the test database
`RAILS_ENV=test bundle exec rake db:drop db:create db:structure:load`

Run this for the tests
`bundle exec rake spec`

## How to Deploy

At the moment we deploy by pushing to heroku:

`git push heroku master` or `git push heroku <branch-name>:master`
