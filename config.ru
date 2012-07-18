$:.unshift 'lib'

require 'travis/api/app'

run Travis::Api::App
