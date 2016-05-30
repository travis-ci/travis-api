require 'coder'
require 'metriks'
require 'travis/model/log/part'
require 'travis/model/job/test'
require 'travis/services/base'

module Travis
  module Logs
    module Services
      class Receive < Travis::Services::Base
        # TODO remove this once we know aggregation works fine and the worker passes a :final flag
        FINAL = 'Done. Build script exited with:'

        register :logs_receive

        def run
          create_part
          notify
        end

        private

          def create_part
            measure('logs.update') do
              Travis.logger.warn "[warn] log.id is #{log.id.inspect} in :logs_append! job_id: #{data[:id]}" if log.id.to_i == 0
              Log::Part.create!(log_id: log.id, content: chars, number: number, final: final?)
            end
          rescue ActiveRecord::ActiveRecordError => e
            Travis.logger.warn "[warn] could not save log in :logs_append job_id: #{data[:id]}: #{e.message}"
            Travis.logger.warn e.backtrace
          end

          def notify
            job.notify(:log, _log: chars, number: number, final: final?)
          rescue => e
            Metriks.meter('travis.logs.update.notify.errors').mark
            Travis.logger.error("Error notifying of log update: #{e.message} (from #{e.backtrace.first})")
          end

          def log
            @log ||= Log.where(job_id: job.id).select(:id).first || create_log
          end

          def create_log
            Travis.logger.warn "[warn] Had to create a log for job_id: #{job.id}!"
            job.create_log!
          end

          def job
            @job ||= Job::Test.find(data[:id])
          end

          def chars
            @chars ||= filter(data[:log])
          end

          def number
            data[:number]
          end

          def final?
            !!data[:final] || chars.include?(FINAL)
          end

          def data
            @data ||= params[:data].symbolize_keys
          end

          def filter(chars)
            Coder.clean!(chars.to_s.gsub("\0", '')) # postgres seems to have issues with null chars
          end

          def measure(name, &block)
            Metriks.timer(name).time(&block)
          end
      end
    end
  end
end
