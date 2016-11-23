# Travis Admin 2.0

## Description
Travis Admin is an application used for viewing and managing Travis accounts and their builds. Additional high-level description to come soon.

## What It Can Do
This is where we will document the features and abilities that admin has. Example for the previous admin is on [the old readme](https://github.com/travis-pro/travis-admin#things-it-can-do).

## Status
Travis Admin (2.0) was build by the Emerald Project team June-November 2016. It falls under Team Sapphire's areas of responsibility.

## Local Setup
### Setup the database for development/test
Go to [travis-pro-migrations](https://github.com/travis-pro/travis-pro-migrations) and follow the instructions there.

### Make a `config/travis.yml`:

You can generate is with trvs:

`trvs generate-config --pro admin-v2 staging  > config/travis.yml`

Manually add "development:" as a parent, nest the updated config info under that, and remove the config for redis (so that we use our local redis instance). Also make sure to remove travis_config=--- if it is at the top of the file.

or use this:

```
development:
  admins:
    - lisbethmarianne
    - sinthetix
  api_endpoint:
    'https://api-staging.travis-ci.com'
  topaz:
    url: https://topaz-staging.travis-ci.com
  redis:
    url: redis://localhost:6379
  billing_endpoint:
   'https://billing-staging.travis-ci.com'
  become_endpoint:
   'https://travis:Goo7shoo@become-staging.travis-ci.com'
  encryption:
    key: [add key]
  service_hook_url: https://notify.staging.travis-ci.com

test:
  admins:
    - travisbot
  api_endpoint:
    'https://api-fake.travis-ci.com'
  redis:
    url: redis://localhost:6380
  topaz:
    url: https://topaz-fake.travis-ci.com
  billing_endpoint:
    'https://billing-fake.travis-ci.com'
  encryption:
    key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  service_hook_url: https://notify.fake.travis-ci.com
```

You need to make sure the correct instance(s) of redis are running locally `redis-server --port 6380`.

You can disable one time passwort in development by adding `disable_otp: true` to your config/travis.yml.

### Use Staging database in development:

1. create a `.env` file in the root directory of travis-admin-v2
2. add `export GITHUB_LOGIN=[your case-sensitive github login]` to this file
3. find the current postgres_url for travis-staging database: `heroku config:get DATABASE_URL -a travis-pro-staging`
4. add `export STAGING_DATABASE_URL=[postgres_url]` to the `.env` file
5. run `source .env`
6. IN THE SAME SHELL run the server: `rails s`
7. Go to <http://localhost:3000>

### Run tests:

1. open a new shell (don't run `source .env`!)
2. run `bundle exec rspec`
(make sure you have your test redis instance running)

## How to Deploy

At the moment we deploy by pushing to heroku:

`git push heroku master` or `git push heroku <branch-name>:master`
