require 'active_support/core_ext/hash/reverse_merge'

module Travis
  module Notification
    require 'travis/notification/instrument'
    require 'travis/notification/publisher'

    class << self
      attr_accessor :publishers

      def setup(options = { instrumentation: true })
        Travis::Instrumentation.setup if options[:instrumentation] && Travis.config.metrics.reporter
        publishers << Publisher::Log.new
        publishers << Publisher::Redis.new if Travis::Features.feature_active?(:notifications_publisher_redis)
      end

      def publish(event)
        publishers.each { |publisher| publisher.publish(event) }
      end
    end

    self.publishers ||= []
  end
end
