# Travis Admin 2.0

Travis Admin is an application for administrating the Travis system. Built by the Emerald Project team June-November 2016, it now falls under Team Jade's areas of responsibility.

## Setup

### Requirements

- [PostgreSQL](https://www.postgresql.org/) installed and running
- [Redis](https://redis.io/) installed and available
- Ruby 2.3.4
- [Bundler](http://bundler.io/)

### First steps

- Clone the repository locally, in the same path as other travis repos like `travis-pro-keychain` or `travis-keychain`.

### Install dependencies

```
bundle install
```

### Generate config

#### Development

Generate the config. This file is already ignored by Git – it should never be committed.

```
trvs generate-config --pro admin staging  > config/travis.yml
```

Manually add `development:` as a parent, nest the updated config data under that, and remove the config for redis (so that we use our local redis instance). Also make sure to remove `travis_config=---` if it appears at the top of the file.

This will look like the following:

```
development:
  logs_database:
    adapter: postgresql
...
```

> Note: When using atom or other text editors, "gitignored" files  like `config/.travis.yml`can be hidden by default. [Here's how to fix this in atom](https://discuss.atom.io/t/gitignored-files-are-hidden-from-tree-view-regardless-of-setting/8724).

#### Test

Append to the `travis.yml` file, the test data from `travis.example.yml`.

```
cat config/travis.example.yml >> config/travis.yml
```

### Disabling OTP (One-Time Password)

Add `disable_otp: true` to the development section of your config.

Now your `config/.travis.yml` should look like the following:

```
development:
  disable_otp: true
  logs_database:
    adapter: postgresql
```

### Connecting to the staging database in development

This is a good idea, because the application is barely usable without a populated database.

Export these environment variables.

```
export GITHUB_LOGIN=YOUR_OWN_GITHUB_LOGIN # replace YOUR_OWN_GITHUB_LOGIN with the real GitHub user name
export STAGING_DATABASE_URL=`heroku config:get DATABASE_URL -a travis-pro-staging`
```

Then start the rails server.

```
bundle exec rails s
```

### Running tests

Run this command once to create the test database.

```
RAILS_ENV=test bundle exec rake db:drop db:create db:structure:load
```

Run this for the tests.

```
bundle exec rake spec
```

### Deployment

At the moment, we deploy through [travisbot](https://builders.travis-ci.com/engineering/runbooks/travisbot/) to the staging application in Heroku.

These are the steps to do so:

1. Set up the required deployment tokens, see [Builders Manual: Deployment ](https://builders.travis-ci.com/engineering/deployment/#How-to%E2%80%A6)
2. Head over to [#deploys](https://travisci.slack.com/messages/C03J1T613) channel in Slack
3. Deploy: `.deploy admin-v2 to staging`
4. You can see the new version live at https://admin-v2-staging.travis-ci.com/


You can also use Heroku directly from the command line:

```
git push heroku master
```
