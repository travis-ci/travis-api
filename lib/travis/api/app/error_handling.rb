require 'travis/api/app'

class Travis::Api::App
  class ErrorHandling

    def self.setup
      return unless Travis.config.sentry.dsn

      Sentry.init do |config|
        config.dsn = Travis.config.sentry.dsn
      end
    end

  end
end
