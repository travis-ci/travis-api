require 'travis/config'

class TravisConfig < Travis::Config
  define admins: [],
         enterprise: false,
         host: 'localhost:3000',
         service_hook_url: '',
         api_endpoint: '',
         become_endpoint: '',
         log_level: 'info',
         ssl: {
           verify: true
         },
         gdpr: {
           endpoint: 'https://gdpr.travis-ci.com',
           auth_token: 'token'
         },
         slack: {
           url: '',
           username: 'Travis Admin v2 (OSS)',
           icon_emoji: ':travis:'
         },
         settings: {
           timeouts: {
             maximums: {
               hard_limit: 240
             }
           }
         },
         yml_checker: { url: '' },
         billing: {
          url: 'https://billing-fake.travis-ci.com',
          auth_key: 'fake_auth_key'
        }
end