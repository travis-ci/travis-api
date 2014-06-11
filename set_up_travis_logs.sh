#!/bin/bash

# clone travis-logs
pushd $HOME
git clone --depth=1 https://github.com/travis-ci/travis-logs.git
cd travis-logs

# install ruby runtime which travis-logs wants
RUBY_RUNTIME=$(cat .ruby-version)
rvm install $RUBY_RUNTIME
# using JRuby, migrate the 'logs' table in 'travis_test' database
BUNDLE_GEMFILE=$PWD/Gemfile
rvm $RUBY_RUNTIME do bundle install
psql -c "CREATE DATABASE travis_logs_test;" -U postgres
cp $TRAVIS_BUILD_DIR/config/database.yml config/travis.yml
rvm $RUBY_RUNTIME do bundle exec rake db:migrate
popd
