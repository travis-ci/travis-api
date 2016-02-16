require 'active_resource'

class Travis::Resource < ActiveResource::Base
  Rails.logger.debug "DEBUG resource"
  self.site = 'https://api.travis-ci.org'
  self.format = :json
  def self.headers
    {
        'Authorization' => 'token D0nqa10GPgIE0Q7rlEIJyQ',
        'Travis-API-Version' => '3',
        'User-Agent' => 'Travis',
        'Accept' => 'application/json'
    }
    Rails.logger.debug "DEBUG headers"
  end
end