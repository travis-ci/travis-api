require 'travis/api/app'

class Travis::Api::App
  class ErrorHandling

    def self.setup
      return unless Travis.config.sentry.dsn
      queue = ::SizedQueue.new(100)
      Thread.new do
        loop do
          begin
            Raven.send queue.pop
          rescue Exception => e
            puts e.message, e.backtrace
          end
        end
      end

      Raven.configure do |config|
        config.async = lambda { |event| queue << event if queue.num_waiting < 100 }
        config.dsn = Travis.config.sentry.dsn
      end
    end

  end
end
