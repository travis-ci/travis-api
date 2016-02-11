class Travis::Resource < ActiveResource::Base
  self.site = 'http://api.travis-ci.com'
  # self.headers['Authorization'] = 'Token token="abcd"'
  # headers['Accept'] = 'application/json'
  # self.prefix = '/example/resources/'
  # self.format = :json
  # Not sure what else we need but that was the example on ARes's readme and other things I found
  # TODO: Actually make this communicate with API.
end