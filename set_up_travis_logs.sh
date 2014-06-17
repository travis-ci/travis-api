#!/bin/bash

travis_retry() {
  local result=0
  local count=1
  while [ $count -le 3 ]; do
    [ $result -ne 0 ] && {
      echo -e "\n${RED}The command \"$@\" failed. Retrying, $count of 3.${RESET}\n" >&2
    }
    "$@"
    result=$?
    [ $result -eq 0 ] && break
    count=$(($count + 1))
    sleep 1
  done

  [ $count -eq 3 ] && {
    echo "\n${RED}The command \"$@\" failed 3 times.${RESET}\n" >&2
  }

  return $result
}

# clone travis-logs
pushd $HOME
git clone --depth=1 https://github.com/travis-ci/travis-logs.git
cd travis-logs

# install ruby runtime which travis-logs wants
RUBY_RUNTIME=$(cat .ruby-version)
rvm install $RUBY_RUNTIME
# using JRuby, migrate the 'logs' table in 'travis_test' database
BUNDLE_GEMFILE=$PWD/Gemfile
travis_retry rvm $RUBY_RUNTIME do bundle install
psql -c "CREATE DATABASE travis_logs_test;" -U postgres
cp $TRAVIS_BUILD_DIR/config/database.yml config/travis.yml
rvm $RUBY_RUNTIME do bundle exec rake db:migrate
popd
