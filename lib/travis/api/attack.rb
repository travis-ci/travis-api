require 'rack/attack'

class Rack::Attack
  class Request
    TOKEN = 'travis.access_token'.freeze

    def travis_token
      env.fetch(TOKEN)
    end

    def authenticated?
      env.include? TOKEN
    end

    def identifier
      authenticated? ? travis_token.to_s : ip
    end
  end

  ####
  # Ban based on: IP address
  # Ban time:     indefinite
  # Ban after:    manually banned
  blacklist('block client requesting from redis') do |request|
    Travis.redis.sismember(:api_blacklisted_ips, request.ip)
  end

  ####
  # Ban based on: IP address or access token
  # Ban time:     1 hour
  # Ban after:    10 POST requests within one minute to /auth/github
  blacklist('hammering /auth/github') do |request|
     Rack::Attack::Allow2Ban.filter(request.identifier, maxretry: 10, findtime: 1.minute, bantime: 1.hour) do
       request.post? and request.path == '/auth/github'
     end
  end

  ###
  # Throttle:  unauthenticated requests - 50 per minute
  # Scoped by: IP address
  throttle('req/ip/1min', limit: 50, period: 1.minute) do |request|
    request.ip unless request.authenticated?
  end

  ###
  # Throttle:  authenticated requests - 200 per minute
  # Scoped by: access token
  throttle('req/token/1min', limit: 200, period: 1.minute) do |request|
    request.identifier
  end

  if ENV["MEMCACHIER_SERVERS"]
    cache.store = Dalli::Client.new(
      ENV["MEMCACHIER_SERVERS"].split(","),
      username:             ENV["MEMCACHIER_USERNAME"],
      password:             ENV["MEMCACHIER_PASSWORD"],
      failover:             true,
      socket_timeout:       1.5,
      socket_failure_delay: 0.2)
  else
    cache.store = ActiveSupport::Cache::MemoryStore.new
  end
end
