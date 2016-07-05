require 'rack/attack'
require 'cidr'

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

  def self.bantime(value)
    case Travis.env
    when "production" then value
    when "staging"    then 10 # ban for 10 seconds on staging
    else 1
    end
  end

  POST_SAFELIST = [
    "/auth/handshake",
    "/auth/post_message",
    "/auth/post_message/iframe"
  ]

  whitelist('safelist build status images') do |request|
    /\.(png|svg)$/.match(request.path)
  end

  # https://help.github.com/articles/what-ip-addresses-does-github-use-that-i-should-whitelist/
  whitelist('safelist anything coming from github') do |request|
    NetAddr::CIDR.create('192.30.252.0/22').contains?(request.ip)
  end

  ####
  # Whitelisted IP addresses
  whitelist('whitelist client requesting from redis') do |request|
    Travis.redis.sismember(:api_whitelisted_ips, request.ip)
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
  # Ban time:     5 hours
  # Ban after:    10 POST requests within five minutes to /auth/github
  blacklist('hammering /auth/github') do |request|
    Rack::Attack::Allow2Ban.filter(request.identifier, maxretry: 2, findtime: 5.minutes, bantime: bantime(5.hours)) do
      request.post? and request.path == '/auth/github'
    end
  end

  ####
  # Ban based on: IP address or access token
  # Ban time:     1 hour
  # Ban after:    10 POST requests within 30 seconds
  blacklist('spamming with POST requests') do |request|
    Rack::Attack::Allow2Ban.filter(request.identifier, maxretry: 10, findtime: 30.seconds, bantime: bantime(1.hour)) do
      request.post? and not POST_SAFELIST.include? request.path
    end
  end


  ###
  # Throttle:  unauthenticated requests to /auth/github - 1 per minute
  # Scoped by: IP address
  throttle('req/ip/1min', limit: 1, period: 1.minute) do |request|
    request.ip unless request.authenticated? and request.path == '/auth/github'
  end

  ###
  # Throttle:  unauthenticated requests - 500 per minute
  # Scoped by: IP address
  throttle('req/ip/1min', limit: 500, period: 1.minute) do |request|
    request.ip unless request.authenticated?
  end

  ###
  # Throttle:  authenticated requests - 2000 per minute
  # Scoped by: access token
  throttle('req/token/1min', limit: 2000, period: 1.minute) do |request|
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
