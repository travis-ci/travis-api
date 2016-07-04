require 'faraday'

class Service::Repository::Enable
  attr_reader :repository_id

  def initialize(repository_id)
    @repository_id = repository_id
  end

  def call
    conn = Faraday.new(:url => 'https://api-staging.travis-ci.com') do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    conn.post do |req|
      req.url "/repo/#{@repository_id}/enable"
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "token #{ENV['TRAVIS_TOKEN']}"
      req.headers['Travis-API-Version'] = '3'
    end
  end
end
