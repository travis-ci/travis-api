require 'active_resource'

class Travis::Resource < ActiveResource::Base
  self.site = 'https://api.travis-ci.org'
  self.headers['Authorization'] = 'Token token="D0nqa10GPgIE0Q7rlEIJyQ"'
  self.headers['Travis-API-Version'] = '3'
  self.headers['User-Agent'] = 'Travis'
  self.format = :json

  # headers['Accept'] = 'application/json'
  # self.prefix = '/example/resources/'
  # Not sure what else we need but that was the example on ARes's readme and other things I found
  # TODO: Actually make this communicate with API.
end