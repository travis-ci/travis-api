# Travis Admin 2.0

Travis Admin is an application for administrating the Travis system. Built by the Emerald Project team June-November 2016, it now falls under Team Jade's areas of responsibility.

## Setup

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

> Note: `config/.travis.yml` is part of the `.gitignore` file and will be ignored by git. When using atom or other text editors, "gitignored" files can be hidden by default. [Here's how to fix this in atom](https://discuss.atom.io/t/gitignored-files-are-hidden-from-tree-view-regardless-of-setting/8724)

#### Test

Append to the `travis.yml` file, the test data from `travis.example.yml`.

```
cat config/travis.example.yml >> config/travis.yml
```

### Disabling OTP (One-Time Password)

Adding `disable_otp: true` to the development section of your config.

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

At the moment, we deploy through travisbot to the staging application in Heroku.

These are the steps to do so:

1. Set up the required deployment tokens, see [Builders Manual: Deployment ](https://builders.travis-ci.com/engineering/deployment/#How-to%E2%80%A6)
2. Head over to [#deploys](https://travisci.slack.com/messages/C03J1T613) channel in Slack
3. Deploy: `.deploy admin-v2 to staging`


You can also use Heroku directly:

```
git push heroku master
```
