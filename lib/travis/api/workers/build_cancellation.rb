require 'sidekiq/worker'
require 'multi_json'

module Travis
  module Sidekiq
    class BuildCancellation
      class ProcessingError < StandardError; end

      include ::Sidekiq::Worker
      # do we need to name the queue here? we didn't do this in Admin. We passed this info in the procfile
      sidekiq_options queue: build_cancellations

      def perform(data)
        Travis.service(:cancel_build, data).run
      end
    end
  end
end