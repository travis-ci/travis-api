require 'sidekiq/worker'
require 'multi_json'

module Travis
  module Sidekiq
    class BuildCancellation
      class ProcessingError < StandardError; end

      include ::Sidekiq::Worker
      # do we need to name the queue here? we didn't do this in Admin. We passed this info in the procfile
      sidekiq_options queue: build_cancellations

      attr_accessor :data

      def perform(data)
        @data = data
        if payload
          service.run
        else
          Travis.logger.warn("The #{type} payload was empty and could not be processed")
        end
      end

      def service
        @service ||= Travis.service(:cancel_build, data)
      end
    end
  end
end