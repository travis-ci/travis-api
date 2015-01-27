require 'sidekiq/worker'
require 'multi_json'

module Travis
  module Sidekiq
    class JobRestart
      class ProcessingError < StandardError; end

      include ::Sidekiq::Worker
      sidekiq_options queue: :job_restarts

      def perform(data)
        user = User.find(data['user_id'])
        Travis.service(:reset_model, user, job_id: data['id']).run
      end

    end
  end
end
