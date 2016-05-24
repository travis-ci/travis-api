require 'support/matchers'
require 'support/payloads'

module Support
  autoload :ActiveRecord,   'support/active_record'
  autoload :Formats,        'support/formats'
  autoload :GCS,            'support/gcs'
  autoload :Log,            'support/log'
  autoload :Mocks,          'support/mocks'
  autoload :Notifications,  'support/notifications'
  autoload :Redis,          'support/redis'
  autoload :S3,             'support/s3'
  autoload :Silence,        'support/silence'
end

