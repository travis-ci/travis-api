#!/bin/bash

function travis_retry() {
  $Local:result = 0
  $Local:count  = 1
  $Local:cmd_string = $args -join ' '

  while ( $count -le 3 ) {
    if ( $result -ne 0 ) {
      Write-Host -foregroundColor Red "`nThe command ""$cmd_string"" failed. Retrying, $count of 3.`n" 2>&1
    }
    Invoke-Expression($cmd_string)
    $result = $LastExitCode
    if ( $result -eq 0 ) {
      break
    }
    $count=$count + 1
    sleep 1
  }

  if ( $count -eq 3 ) {
    Write-Host -foregroundColor Red "`nThe command ""$cmd_string"" failed 3 times.`n" 2>&1
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
