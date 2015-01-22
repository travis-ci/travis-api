require 'sidekiq/worker'
require 'multi_json'

module Travis
  module Sidekiq
    class BuildCancellation
      class ProcessingError < StandardError; end

      include ::Sidekiq::Worker
      sidekiq_options queue: :build_cancellations

      def perform(data)
        Travis.service(:cancel_build, data).run
      end
    end
  end
end
