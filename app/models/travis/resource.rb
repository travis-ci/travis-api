require 'active_resource'

class Travis::Resource < ActiveResource::Base
  include ActionController::HttpAuthentication::Token
  self.site = 'https://api.travis-ci.org'
  self.format = :json
  def self.headers
    {
        'Authorization' => 'token D0nqa10GPgIE0Q7rlEIJyQ',
        'Travis-API-Version' => '3',
        'User-Agent' => 'Travis',
        'Accept' => 'application/json'
    }
  end
end