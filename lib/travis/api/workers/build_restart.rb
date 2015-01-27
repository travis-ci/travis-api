require 'sidekiq/worker'
require 'multi_json'

module Travis
  module Sidekiq
    class BuildRestart
      class ProcessingError < StandardError; end

      include ::Sidekiq::Worker
      sidekiq_options queue: :build_restarts

      def perform(data)
        user = User.find(data['user_id'])
        Travis.service(:reset_model, user, build_id: data['id']).run
      end

    end
  end
end
