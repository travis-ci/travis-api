require 'core_ext/module/include'
require 'active_support/core_ext/string/inflections'

module Travis

  # Event handlers register to events that are issued from state change
  # events on the core domain models (such as Request, Build and Job::Test).
  #
  # Handler registrations are defined in Travis.config so they can be added or
  # removed easily for different environments.
  #
  # Note that Travis::Event#notify accepts an internal event name like
  # 'create' (coming from the simple_states implementation in the models) and
  # turns it into a namespaced client event name like 'job:test:created').
  # Notification handlers register for and deal with these client event names.
  module Event
    require 'travis/event/config'
    require 'travis/event/handler'
    require 'travis/event/subscription'

    SUBSCRIBERS = %w(metrics)

    class << self
      include Logging

      def subscriptions
        @subscriptions ||= subscribers.map do |name|
          name = 'github_status' if name == 'github_commit_status' # TODO compat, remove once configs have been updated
          subscription = Subscription.new(name)
          subscription if subscription.subscriber
        end.compact
      end

      def dispatch(event, *args)
        subscriptions.each do |subscription|
          subscription.notify(event, *args)
        end
      end

      def subscribers
        (SUBSCRIBERS + Travis.config.notifications).uniq
      end
    end

    def notify(event, *args)
      Travis::Event.dispatch(client_event(event, self), self, *args)
    end

    protected

      def client_event(event, object)
        event = "#{event}ed".gsub(/eded$|eed$/, 'ed') unless [:log, :ready].include?(event)
        namespace = object.class.name.underscore.gsub('/', ':').gsub(/travis:model:/, '')
        [namespace, event].join(':')
      end
  end
end
