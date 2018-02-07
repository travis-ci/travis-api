require 'travis/config'

module Travis
  class Config < Hashr

    class << self
      def logs_api_url
        ENV['TRAVIS_API_LOGS_API_URL'] ||
          ENV['LOGS_API_URL'] ||
          'http://travis-logs-notset.example.com:1234'
      end

      def logs_api_auth_token
        ENV['TRAVIS_API_LOGS_API_AUTH_TOKEN'] ||
          ENV['LOGS_API_AUTH_TOKEN'] ||
          'notset'
      end
    end

    HOSTS = {
      production:  'travis-ci.org',
      staging:     'staging.travis-ci.org',
      development: 'localhost:3000'
    }

    define  host:  'travis-ci.org',
            shorten_host:  'trvs.io',
            tokens:        { internal: 'token' },
            auth:          { target_origin: nil },
            assets:        { host: HOSTS[Travis.env.to_sym] },
            amqp:          { username: 'guest', password: 'guest', host: 'localhost', prefetch: 1 },
            database:      { adapter: 'postgresql', database: "travis_#{Travis.env}", encoding: 'unicode', min_messages: 'warning', variables: { statement_timeout: 10_000 } },
            logs_database: { adapter: 'postgresql', database: "travis_logs_#{Travis.env}", encoding: 'unicode', min_messages: 'warning', variables: { statement_timeout: 10_000 } },
            logs_readonly_database: { adapter: 'postgresql', database: "travis_logs_#{Travis.env}", encoding: 'unicode', min_messages: 'warning', variables: { statement_timeout: 10_000 } },
            logs_api:      { url: logs_api_url, token: logs_api_auth_token },
            log_options:   { s3: { access_key_id: '', secret_access_key: ''}},
            s3:            { access_key_id: '', secret_access_key: ''},
            pusher:        { app_id: 'app-id', key: 'key', secret: 'secret' },
            sidekiq:       { namespace: 'sidekiq', pool_size: 1 },
            smtp:          {},
            email:         {},
            github:        { api_url: 'https://api.github.com', token: 'travisbot-token' },
            async:         {},
            notifications: [], # TODO rename to event.handlers
            metrics:       { reporter: 'librato' },
            logger:        { thread_id: true },
            queues:        [],
            default_queue: 'builds.linux',
            jobs:          { retry: { after: 60 * 60 * 2, max_attempts: 1, interval: 60 * 5 } },
            queue:         { limit: { default: 5, by_owner: {} }, interval: 3 },
            logs:          { shards: 1, intervals: { vacuum: 10, regular: 180, force: 3 * 60 * 60 } },
            roles:         {},
            archive:       {},
            ssl:           {},
            redis:         { url: 'redis://localhost:6379' },
            redis_gatekeeper: { url: ENV['REDIS_GATEKEEPER_URL'] || 'redis://localhost:6379' },
            repository:    { ssl_key: { size: 4096 } },
            encryption:    Travis.env == 'development' || Travis.env == 'test' ? { key: 'secret' * 10 } : {},
            sync:          { organizations: { repositories_limit: 1000 } },
            states_cache:  { memcached_servers: 'localhost:11211' },
            sentry:        {},
            services:      { find_requests: { max_limit: 100, default_limit: 25 } },
            settings:      { timeouts: { defaults: { hard_limit: 50, log_silence: 10 }, maximums: { hard_limit: 180, log_silence: 60 } },
                             rate_limit: { defaults: { api_builds: 10 }, maximums: { api_builds: 200 } } },
            endpoints:     {},
            oauth2:        {},
            webhook:       { public_key: nil },
            cache_options: {}

    default :_access => [:key]

    def initialize(*)
      super
      load_urls
    end

    def metrics
      super.to_h.merge(librato: librato.to_h.merge(source: librato_source), graphite: graphite)
    end
  end
end
