# Travis Admin 2.0 :sparkles:

## Description
Travis Admin is an application used for viewing and managing Travis accounts and their builds. Additional high-level description to come soon.

## What It Can Do
This is where we will document the features and abilities that admin has. Example for the previous admin is on [the old readme](https://github.com/travis-pro/travis-admin#things-it-can-do).

## Status
Travis Admin (2.0) is actively maintained by the Emerald Project team and falls under Team Sapphire's areas of responsibility.

## In The System

## Local Setup
### Setup the database for development/test
Go to [travis-pro-migrations](https://github.com/travis-pro/travis-pro-migrations) and follow the instructions there.

Use Staging database in development:

1. create a `.env` file in the root directory of travis-admin-v2
2. add `export GITHUB_LOGIN=[your case-sensitive github login]` to this file
3. find the current postgres_url for travis-staging database: `heroku config:get DATABASE_URL -a travis-pro-api-staging`
4. add `export DATABASE_URL=[DATABASE_URL]` to the `.env` file
5. run `source .env`
6. IN THE SAME SHELL run the server: `rails s`
7. Go to <http://localhost:3000>

## How to Deploy

## License
