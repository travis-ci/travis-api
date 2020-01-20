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
            Travis::Lock.exclusive("enqueue_cron_jobs", options) do
              Metriks.timer("api.v3.cron_scheduler.enqueue").time { enqueue }
            end
          rescue Travis::Lock::Redis::LockError => e
            Travis.logger.error e.message
          end
          sleep(Travis::API::V3::Models::Cron::SCHEDULER_INTERVAL)
        end
      end

      def self.options
        @options ||= {
          strategy: :redis,
          url:      Travis.config.redis.url,
          retries:  0
        }
      end

      def self.pgsql_options
        @pgsql_options ||= {
          strategy: :postgresql,
          try: true,
          transactional: false
        }
      end

      def self.enqueue
        begin
          Travis::Lock.exclusive("pgsql_enqueue_cron_jobs", pgsql_options) do
            scheduled = Travis::API::V3::Models::Cron.scheduled
            count = scheduled.count

            Travis.logger.info "Found #{count} cron jobs to enqueue" if count > 0
            Metriks.gauge("api.v3.cron_scheduler.upcoming_jobs").set(count)

            scheduled.each do |cron|
              begin
                cron.needs_new_build? ? cron.enqueue : cron.skip_and_schedule_next_build
                Travis.logger.info "Enqueued cron id: #{cron.try(:id)}"
              rescue => e
                Metriks.meter("api.v3.cron_scheduler.enqueue.error").mark
                Raven.capture_exception(e, tags: { 'cron_id' => cron.try(:id) })
                Travis.logger.error "Cron id: #{cron.try(:id)} with message:#{e.message}"
                next
              end
            end
          end
        rescue => e
          Travis.logger.error "Pgsql lock error with message:#{e.message}"
        end
        
      end
    end
  end
end
