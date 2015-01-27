require 'sidekiq/worker'
require 'multi_json'

module Travis
  module Sidekiq
    class BuildCancellation
      class ProcessingError < StandardError; end

      include ::Sidekiq::Worker
      sidekiq_options queue: :build_cancellations

      def perform(data)
        user = User.find(data['user_id'])
        Travis.service(:cancel_build, user, { id: data['id'], source: data['source'] }).run
      end

    end
  end
end
