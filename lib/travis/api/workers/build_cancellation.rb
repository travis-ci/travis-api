require 'sidekiq/worker'
require 'multi_json'

module Travis
  module Sidekiq
    class BuildCancellation
      class ProcessingError < StandardError; end

      include ::Sidekiq::Worker
      sidekiq_options queue: :build_cancellations

      def perform(data)
        p "#######################"
        p data
        user = User.find(data['user_id'])
        test = { id: data['id'], source: data['source'] }
        p test
        Travis.service(:cancel_build, user, { id: data['id'], source: data['source'] }).run
      end

    end
  end
end
