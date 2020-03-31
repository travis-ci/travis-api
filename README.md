# Travis Admin 2.0

Travis Admin is an application for administrating the Travis system. Built by the Emerald Project team June-November 2016, it now falls under Team Jade's areas of responsibility.

## Setup

### Requirements

- [PostgreSQL](https://www.postgresql.org/) installed and running
- [Redis](https://redis.io/) installed and available
- Ruby 2.3.4
- [Bundler](http://bundler.io/)
- [PhantomJS](http://phantomjs.org/)

### Travis CI Repository Requirements
- [Trvs](https://github.com/travis-ci/trvs)
- [Travis-Keychain](https://github.com/travis-pro/travis-keychain)
- [Travis-Pro-Keychain](https://github.com/travis-pro/travis-pro-keychain)

### First steps

- Clone the repository locally, in the same path as other travis repos like `travis-pro-keychain` or `travis-keychain`.

### Install dependencies

```
bundle install
```

### Generate config

#### Development
To generate the config please run the command below. This file is already ignored by Git and it should **never** be committed.


```
trvs generate-config --pro admin staging  > config/travis.yml
```

### Add config/database.yml
`cp config/database.default.yml config/database.yml`

#### Edit config/travis.yml
Manually add `development:` as the top parent attribute, nest the updated config data under it, and remove the config for redis (so that we use our local redis instance). Also make sure to remove `travis_config=---` if it appears at the top of the file.

This will look like the following:

```
development:
  logs_database:
    adapter: postgresql
  admins:
  - someone
...
```

> Note: When using atom or other text editors, "gitignored" files  like `config/.travis.yml`can be hidden by default. [Here's how to fix this in atom](https://discuss.atom.io/t/gitignored-files-are-hidden-from-tree-view-regardless-of-setting/8724).

#### Enterprise

Add `enterprise: true` to the development section of your `config/.travis.yml` like so:

```
development:
  enterprise: true

```

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
3. Deploy: `.deploy admin-v2 to com-staging` (or `.deploy admin-v2 to org-staging`)
4. You can see the new version live at:
  * _com-staging_ : https://https://travis-pro-admin-v2-staging.herokuapp.com/
  * _org-staging_ : https://travis-admin-v2-staging.herokuapp.com/


You can also use Heroku directly from the command line:

```
git push heroku master
```

## Steps to produce a clean staging database dump

```
heroku -a travis-pro-staging pg:backups:capture
heroku -a travis-pro-staging pg:backups:download
```

This produces a **latest.dump** file. To import the dump to a local database:

```
createdb travis_pro_staging
pg_restore --verbose --clean --no-acl --no-owner -h localhost -U myuser -d travis_pro_staging latest.dump
```

Run `psql travis_pro_staging` and enter the following queries to remove sensitive data:

```
update users set (github_oauth_token, email) = (null, 'dbdump@test.com');
update repositories set owner_email = 'dbdump@test.com';
update organizations set email = 'dbdump@test.com';
update subscriptions set (cc_token, vat_id, cc_owner, cc_last_digits, cc_expiration_date, billing_email, coupon) = (null, null, null, null, null, 'dbdump@test.com', null);
update emails set email = 'dbdump@test.com';
delete from stripe_events;
delete from tokens;
delete from ssl_keys;
```

Reexport the dump:

```
pg_dump -Fc --no-acl --no-owner -h localhost -U myuser travis_pro_staging > travis_pro_staging_<date>.dump
```

In case of .dump file requires `joe` role do the following:
```
sudo psql -U $(whoami) postgres
CREATE ROLE joe WITH LOGIN SUPERUSER;

pg_restore --verbose --clean --no-acl --no-owner -h localhost -U joe -d travis_development dump_name.dump
```
