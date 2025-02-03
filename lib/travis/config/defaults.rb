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

      def fallback_logs_api_auth_url
        ENV['TRAVIS_API_FALLBACK_LOGS_API_URL'] || 'http://travis-logs-notset.example.com:1234'
      end

      def fallback_logs_api_auth_token
        ENV['TRAVIS_API_FALLBACK_LOGS_API_TOKEN'] || 'notset'
      end
    end

    HOSTS = {
      production:  'travis-ci.org',
      staging:     'staging.travis-ci.org',
      development: 'localhost:3000'
    }

    define  host:                 'travis-ci.org',
            api_com_url:          'https://api.travis-ci.com',
            api_org_url:          'https://api.travis-ci.org',
            shorten_host:         'trvs.io',
            public_mode:          !!ENV['PUBLIC_MODE'],
            applications:         {},
            tokens: {
              internal: 'token',
              web_token: {
                expires_in: ENV['WEB_TOKEN_EXPIRES_IN_HOURS'] == 'unlimited' ? 2 * 365 * 86_400 : (ENV['WEB_TOKEN_EXPIRES_IN_HOURS'] ? ENV['WEB_TOKEN_EXPIRES_IN_HOURS'].to_i * 3_600 : 1 * 3_600)
              },
              auth_token: {
                expires_in: ENV['AUTH_TOKEN_EXPIRES_IN_DAYS'] == 'unlimited' ? 2 * 365 * 86_400 : (ENV['AUTH_TOKEN_EXPIRES_IN_DAYS'] ? ENV['AUTH_TOKEN_EXPIRES_IN_DAYS'].to_i * 86_400 : 90 * 86_400)
              },
              auth_cli_token: {
                expires_in: ENV['AUTH_CLI_TOKEN_EXPIRES_IN_DAYS'] == 'unlimited' ? 2 * 365 * 86_400 : (ENV['AUTH_CLI_TOKEN_EXPIRES_IN_DAYS'] ? ENV['AUTH_CLI_TOKEN_EXPIRES_IN_DAYS'].to_i * 86_400 : 90 * 86_400)
              }
            },
            auth:                 { target_origin: nil },
            assets:               { host: HOSTS[Travis.env.to_sym] },
            amqp:                 { username: 'guest', password: 'guest', host: 'localhost', prefetch: 1 },
            closeio:              { key: 'key' },
            gdpr:                 {},
            database:             { adapter: 'postgresql', database: "travis_#{Travis.env}", encoding: 'unicode', min_messages: 'warning', variables: { statement_timeout: ENV['TRAVIS_DB_STATEMENT_TIMEOUT'] || 10000 } },
            db:                   { max_statement_timeout_in_seconds: 15, slow_host_max_statement_timeout_in_seconds: ENV['TRAVIS_MAX_DB_STATEMENT_TIMEOUT'] || 60},
            log_options:          { s3: { access_key_id: '', secret_access_key: ''}},
            s3:                   { access_key_id: '', secret_access_key: ''},
            pusher:               { app_id: 'app-id', key: 'key', secret: 'secret' },
            sidekiq:              { namespace: 'sidekiq', pool_size: 1 },
            smtp:                 {},
            email:                {},
            github:               { api_url: 'https://api.github.com', token: 'travisbot-token' },
            github_apps:          { id: nil, private_pem: nil },
            async:                {},
            notifications:        [], # TODO rename to event.handlers
            metrics:              { reporter: 'librato' },
            logger:               { thread_id: true },
            queues:               [],
            default_queue:        'builds.linux',
            jobs:                 { retry: { after: 60 * 60 * 2, max_attempts: 1, interval: 60 * 5 } },
            queue:                { limit: { default: 5, by_owner: {} }, interval: 3 },
            logs:                 { shards: 1, intervals: { vacuum: 10, regular: 180, force: 3 * 60 * 60 } },
            roles:                {},
            archive:              {},
            ssl:                  {},
            redis:                { url: 'redis://localhost:6379' , ssl: ENV['REDIS_SSL'] || false },
            redis_gatekeeper:     { url: ENV['REDIS_GATEKEEPER_URL'] || 'redis://localhost:6379', ssl: ENV['REDIS_GATEKEEPER_SSL'] || false },
            repository:           { ssl_key: { size: 4096 } },
            encryption:           Travis.env == 'development' || Travis.env == 'test' ? { key: 'secret' * 10 } : {},
            sync:                 { organizations: { repositories_limit: 1000 } },
            states_cache:         { memcached_servers: 'localhost:11211' },
            sentry:               {},
            services:             { find_requests: { max_limit: 100, default_limit: 25 } },
            settings:             { timeouts: { defaults: { hard_limit: 50, log_silence: 10 }, maximums: { hard_limit: 180, log_silence: 60 } },
                                    rate_limit: { defaults: { api_builds: 10 }, maximums: { api_builds: 200 } } },
            endpoints:            {},
            oauth2:               {},
            webhook:              { public_key: nil },
            cache_options:        {},
            build_backup_options: ENV['GCE_BUILD_BACKUP_OPTIONS'] ? JSON.parse(ENV['GCE_BUILD_BACKUP_OPTIONS']) : { gcs: { bucket_name: 'fillme', json_key: JSON.parse("{\n  \"type\": \"service_account\",\n  \"project_id\": \"fillme\",\n  \"private_key_id\": \"b1c57117b4a0b8ae2af2f45b19a1cf9727bc6caf\",\n  \"private_key\": \"-----BEGIN PRIVATE KEY-----\\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDRaHA5z0vXNVSr\\nlLVd/smJpNkpzk4BoHq+zcuuzvKTf1ZY1LnrAhldUbDTKY67c06eOYwVrQc3tEIp\\nJCNhIDNY1lRfGJag6t2v5C710WY+X7qVnRhSpgthvWFX/Rm9KIv3be8AJvUTMUDQ\\nAL10eYrIWJOI/J59khuKvr7khIlysASwGoZc8UgcufxGuwCziNyEIfH1nxiBKILR\\nM1+LdYi/Avyb4bQth5x03THVEmdRDjV7Yoo2c17XElIXtkl03nUce4w8BCu+T1G2\\nKRkApHcQ8R0BDTjjBzaQuXTtTpLvkmZzJ1i0/kPNdnT70lv6N2nI1AN2DVkXDCkG\\nNlZ283W7AgMBAAECggEAC/W6CyMywqzSFCafISovGoRmvsOAowkmWYVpb6d0JUZt\\niQ9FOw3YowLKZZUHCN+yCslgndBPDDhoWu8schyjshwzn2bJG5GubaBLqlB2VXOk\\nNW1OeVHwbnmheKQE90+8hropn0maT6lNeVPBfkh+y6h7bKR47NUOa6MvRd/n9bvL\\nT7pP5ZAHoPoTcbUftOX0gDq0u+uRULe/rduxB0S2EHDEtZEH+ioUOP9AomnaRDSy\\n0spH1s2FUZxIbKBQzsrqMCai4MSjeUrJMTR3ZlpfXePirettvilSWqEXDLvvwaak\\ngehELuM5lH4T49wf4PmEYZ8Jqkh9ku+oNYJdJvGR2QKBgQD7KjhJx9usl0afrIH3\\nw7saHELluWGqHNa6j+TJDpY7N5lLLIym/br9d+cuLTF5CBEHJ502coDR9cyrLVZX\\na05CGmEfSVrSrLUyAU+mHHdsn8n6CCATmlgtPyzzt2c29J7dHUZL94zW/yG6Btg6\\nm+nY4eBKreLpj0+3KbhI/q0q1wKBgQDVcG8Ek3Kt2buOrpDBqxcwB31QljntT+7+\\nYcTZctYL/y7Lm2VcTjserNa3AjG59Z5iaQjKFPhbAvMHfppklyiVSVBRfn4bLTcx\\nSM9I+lntODtGI/BiHVE7hfoYKzwz/3Aj3npiOO9xnOfAgEubGn9DrOzLXPsvWN7E\\nz+/iSr4zvQKBgHFVB7kjGZizWgbKzIqEI3UQs479K3ibMrlUHKQslNV7rQwiugTQ\\nEQQ2inZnph866JQV5/adjEsxYn0LJB6mKNXjGVgIvZa6n7hEpzAJQEoff//2kqLF\\nzmv8SchfRY+iqdyUTRgSR9broMhUNlWb7NUUdyS7edxx8kJv7NvjLzhZAoGAMre9\\n2bOD26XSeKwof6y9HM+ayox4BVkqLE5lLVqpXD5uCznI0y9PwxFFEEW4NT0VPsNA\\nsGxdO5suzsgZve9hWGAMcuEA7EpJRC/N+cRrm//xrdAabeYTiHZkoFudualoJ03V\\nfQOUekXTmB2kWZ3pQdaUihp1IaIXhWL32Kj0G20CgYAfGInHUZf5mqxRK/id8B5Q\\nYmpnLDXsNu1I4qFKeaBo4dF2SGByNW7fVbK/BdCSg5Ov3Ui6m3QWBbJXh1a8QVYA\\nICvwJWqm53bNpocrFPAeXLy9xL5/5CEeVGQNcxFvUF3QgaPVmjbTsZk8vjbidUZk\\nOU8bArrUjGTxNJOe7GebhA==\\n-----END PRIVATE KEY-----\\n\",\n  \"client_email\": \"service@fillme.iam.gserviceaccount.com\",\n  \"client_id\": \"100937792194965642651\",\n  \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\",\n  \"token_uri\": \"https://oauth2.googleapis.com/token\",\n  \"auth_provider_x509_cert_url\": \"https://www.googleapis.com/oauth2/v1/certs\",\n  \"client_x509_cert_url\": \"https://www.googleapis.com/robot/v1/metadata/x509/service%40fillme.iam.gserviceaccount.com\"\n}\n") } },
            merge:                { auth_token: 'merge-auth-token', api_url: 'https://merge.localhost' },
            force_authentication: false,
            read_only:            ENV['READ_ONLY'] || false,
            job_log_access_permissions: { time_based_limit: false, access_based_limit: false, older_than_days: 365, max_days_value: 730, min_days_value: 30 },
            billing:              {},
            vcs:                  {},
            yml:                  { url: 'https://yml.travis-ci.org', token: 'secret', auth_key: 'abc123' },
            logs_api:             { url: logs_api_url, token: logs_api_auth_token },
            fallback_logs_api:    { url: fallback_logs_api_auth_url, token: fallback_logs_api_auth_token },
            scanner:              {},
            insights:             { endpoint: 'https://insights.travis-ci.dev/', auth_token: 'secret' },
            authorizer:           { url: 'http://authorizer', auth_key: 'secret' },
            recaptcha:            { endpoint: 'https://www.google.com', secret: ENV['RECAPTCHA_SECRET_KEY'] || '' },
            antifraud:            { captcha_max_failed_attempts: 3, captcha_block_duration: 24, credit_card_max_failed_attempts: 3, credit_card_block_duration: 24 },
            legacy_roles:         false,
            internal_users:       [{id: 0, login: 'cron'}]

    default :_access => [:key]

    def initialize(*)
      super
      load_urls
    end

    def com_url
      "https://#{host.sub(/org$/, 'com')}"
    end

    def org?
      host.ends_with?('travis-ci.org')
    end

    def com?
      host.ends_with?('travis-ci.com')
    end
  end
end
