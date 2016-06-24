require 'sidekiq/worker'
require 'multi_json'

module Travis
  module Sidekiq
    class JobCancellation
      class ProcessingError < StandardError; end

      include ::Sidekiq::Worker
      sidekiq_options queue: :job_cancellations

      def perform(data)
        user = User.find(data['user_id'])
        Travis.service(:cancel_job, user, { id: data['id'], source: data['source'] }).run
      end
    end
  end
end
