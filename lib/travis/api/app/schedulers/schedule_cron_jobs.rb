require "travis/lock"
require "redlock"
require "metriks"

class Travis::Api::App
  module Schedulers
    class ScheduleCronJobs < Travis::Services::Base
      register :schedule_cron_jobs

      def self.run
        loop do
          begin
            Travis.logger.warn "#{self.object_id}: before lock"
            Travis::Lock.exclusive("enqueue_cron_jobs", options) do
              Travis.logger.warn "#{self.object_id}: has lock"
              Metriks.timer("api.v3.cron_scheduler.enqueue").time { enqueue }
            end
          rescue Travis::Lock::Redis::LockError => e
            Travis.logger.warn "#{self.object_id}: failed to get lock"
            Travis.logger.error e.message
          end
          interval = Travis::API::V3::Models::Cron::SCHEDULER_INTERVAL.to_i
          if !!ENV['TRAVIS_CRON_RANDOM_INTERVAL']
                interval += rand(ENV['TRAVIS_CRON_RANDOM_INTERVAL'].to_i)
          end
          Travis.logger.warn "#{self.object_id}: sleeping #{interval}"
          sleep(interval)
        end
      end

      def self.options
        @options ||= {
          strategy: :redis,
          url:      Travis.config.redis.url,
          retries:  0
        }
      end

      def self.enqueue
        scheduled = Travis::API::V3::Models::Cron.scheduled
        count = scheduled.count

        Travis.logger.info "Found #{count} cron jobs to enqueue" if count > 0
        Metriks.gauge("api.v3.cron_scheduler.upcoming_jobs").set(count)

        scheduled.each do |cron|
          begin
            cron.needs_new_build? ? cron.enqueue : cron.skip_and_schedule_next_build
          rescue => e
            Metriks.meter("api.v3.cron_scheduler.enqueue.error").mark
            Raven.capture_exception(e, tags: { 'cron_id' => cron.try(:id) })
            next
          end
        end
      end
    end
  end
end
