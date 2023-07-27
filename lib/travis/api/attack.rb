require 'rack/attack'
require 'ipaddress'
require 'metriks'

ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
  req = req[:request] if req.is_a?(Hash)
  metric_name = [
    'api.rate_limiting',
    req.env['rack.attack.match_type'],
    req.env['rack.attack.matched'],
  ].join('.')

  ::Metriks.meter(metric_name).mark
end

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

  GITHUB_CIDRS = [
    IPAddress.parse('192.30.252.0/22'),
    IPAddress.parse('185.199.108.0/22'),
  ]

  safelist('build_status_image') do |request|
    /\.(png|svg)$/.match(request.path)
  end

  # https://help.github.com/articles/github-s-ip-addresses/
  safelist('github_request_ip') do |request|
    request.ip && IPAddress(request.ip).ipv4? && GITHUB_CIDRS.any? { |block|
      block.include?(IPAddress(request.ip))
    }
  end

  ####
  # Whitelisted IP addresses
  safelist('ip_in_redis') do |request|
    # TODO: deprecate :api_whitelisted_ips in favour of api_safelisted_ips
    request.ip && (Travis.redis.sismember(:api_whitelisted_ips, request.ip) || Travis.redis.sismember(:api_safelisted_ips, request.ip))
  end

  ####
  # Ban based on: IP address
  # Ban time:     indefinite
  # Ban after:    manually banned
  blocklist('ip_in_redis') do |request|
    # TODO: deprecate :api_blacklisted_ips in favour of api_blocklisted_ips
    Travis.redis.sismember(:api_blacklisted_ips, request.ip) || Travis.redis.sismember(:api_blocklisted_ips, request.ip)
  end

  ####
  # Ban based on: IP address or access token
  # Ban time:     5 hours
  # Ban after:    10 POST requests within five minutes to /auth/github
  blocklist('hammering_auth_github') do |request|
    Rack::Attack::Allow2Ban.filter(request.identifier, maxretry: 2, findtime: 5.minutes, bantime: bantime(5.hours)) do
      request.post? and request.path == '/auth/github'
    end
  end

  ####
  # Ban based on: IP address or access token
  # Ban time:     1 hour
  # Ban after:    50 POST requests within 30 seconds
  blocklist('spamming_post_requests') do |request|
    Rack::Attack::Allow2Ban.filter(request.identifier, maxretry: 50, findtime: 30.seconds, bantime: bantime(1.hour)) do
      request.post? and not POST_SAFELIST.include? request.path
    end
  end

  ####
  # Ban based on: blocked urls
  # Ban time:     indefinite
  # Ban after:    manually banned
  blocklist('repo_banned_in_redis') do |request|
    if request.params["repository_id"] && request.path == "/builds" && Travis.redis.sismember(:api_blocklisted_repos, request.params["repository_id"])
      Travis.redis.sadd(:api_blocklisted_ips, request.ip)
    end
  end

  ###
  # Throttle:  unauthenticated requests to /auth/github - 1 per minute
  # Scoped by: IP address
  throttle('req_ip_1min', limit: 1, period: 1.minute) do |request|
    request.ip unless request.authenticated? and request.path == '/auth/github'
  end

  ###
  # Throttle:  unauthenticated requests - 500 per minute
  # Scoped by: IP address
  throttle('req_ip_1min', limit: 500, period: 1.minute) do |request|
    request.ip unless request.authenticated?
  end

  ###
  # Throttle:  authenticated requests - 2000 per minute
  # Scoped by: access token
  throttle('req_token_1min', limit: 2000, period: 1.minute) do |request|
    request.identifier
  end

  ###
  # Throttle:  authenticated requests for /coupons/ - 20 per day
  # Scoped by: access token
  throttle('req_coupons_1day', limit: 20, period: 1.day) do |request|
    request.identifier if request.path.start_with?('/coupons/')
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
