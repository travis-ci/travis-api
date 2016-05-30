require 'active_support/inflector/inflections.rb'
require 'metriks'

module Travis
  module Event

    # Event handlers subscribe to events issued from core models (such
    # as Build and Job::Test).
    #
    # Subscriptions are defined in Travis.config so they can easily be
    # added/removed for an environment.
    #
    # Subscribing classes are supposed to define an EVENTS constant which holds
    # a regular expression which will be matched against the event name.
    class Subscription
      class << self
        def register(name, const)
          handlers[name.to_sym] = const
        end

        def handlers
          @handlers ||= {}
        end
      end

      attr_reader :name

      def initialize(name)
        @name = name
      end

      def subscriber
        self.class.handlers[name.to_sym] || Handler.const_get(name.to_s.camelize, false)
      rescue NameError => e
        Travis.logger.error "Could not find event handler #{name.inspect}, ignoring."
        nil
      end

      def patterns
        subscriber ? Array(subscriber::EVENTS) : []
      end

      def notify(event, *args)
        if matches?(event)
          subscriber.notify(event, *args)
          increment_counter(event)
        end
      end

      def matches?(event)
        patterns.any? { |patterns| patterns.is_a?(Regexp) ? patterns.match(event) : patterns == event }
      end

      def increment_counter(event)
        # TODO ask mathias about this metric
        metric = "travis.notifications.#{name}.#{event.gsub(/:/, '.')}"
        Metriks.meter(metric).mark
      end
    end
  end
end
