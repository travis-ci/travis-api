require 'active_support/core_ext/object/blank'
require 'travis/support/logging'
require 'travis/support/instrumentation'
require 'travis/support/exceptions/handling'

require 'travis/api'
require 'travis/event/config'
require 'travis/model/build'

module Travis
  module Event
    class Handler
      require 'travis/event/handler/metrics'
      require 'travis/event/handler/trail'

      include Logging
      extend  Instrumentation, Exceptions::Handling

      class << self
        def notify(event, object, data = {})
          payload = Api.data(object, for: 'event', version: 'v0', params: data) if object.is_a?(Build)
          handler = new(event, object, data, payload)
          handler.notify if handler.handle?
        end
      end

      attr_reader :event, :object, :data, :payload

      def initialize(event, object, data = {}, payload = {})
        @event   = event
        @object  = object
        @data    = data
        @payload = payload
      end

      def notify
        handle
      end
      # TODO disable instrumentation in tests
      instrument :notify
      rescues :notify, from: Exception

      private

        def config
          # TODO: we should decrypt things in tasks, not in event handler,
          #       secure_key should be passed to the task and then it should
          #       decrypt the values, which task needs
          @config ||= Config.new(payload, secure_key)
        end

        def repository
          @repository ||= payload['repository']
        end

        def job
          @job ||= payload['job']
        end

        def build
          @build ||= payload['build']
        end

        def request
          @request ||= payload['request']
        end

        def commit
          @commit ||= payload['commit']
        end

        def secure_key
          object.respond_to?(:repository) ? object.repository.key : nil
        end

        def pull_request?
          build['pull_request']
        end
    end
  end
end
