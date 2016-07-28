require 'active_support/core_ext/object/try'
require 'core_ext/hash/compact'

module Travis
  module Notification
    class Instrument
      require 'travis/notification/instrument/event_handler'
      require 'travis/notification/instrument/task'

      class << self
        def attach_to(const)
          statuses = %w(received completed failed)
          instrumented_methods(const).product(statuses).each do |method, status|
            ActiveSupport::Notifications.subscribe(/^#{const.instrumentation_key}(\..+)?.#{method}:#{status}/) do |message, args|
              publish(message, method, status, args)
            end
          end
        end

        def instrumented_methods(const)
          consts = ancestors.select { |const| (const.name || '')[0..5] == 'Travis' }
          methods = consts.map { |const| const.public_instance_methods(false) }.flatten.uniq
          methods = methods.map { |method| method.to_s =~ /^(.*)_(received|completed|failed)$/ && $1 }
          methods.compact.uniq
        end

        def publish(event, method, status, payload)
          instrument = new(event, method, status, payload)
          callback = :"#{method}_#{status}"
          instrument.respond_to?(callback) ? instrument.send(callback) : instrument.publish
        end
      end

      attr_reader :target, :method, :status, :result, :exception, :meta

      def initialize(event, method, status, payload)
        @method, @status = method, status
        @target, @result, @exception = payload.values_at(:target, :result, :exception)
        started_at, finished_at = payload.values_at(:started_at, :finished_at)
        @meta = {
          uuid:        Travis.uuid,
          event:       event,
          started_at:  started_at,
          finished_at: finished_at,
          duration:    finished_at ? finished_at - started_at : nil,
        }.compact
      end

      def publish(data = {})
        message = "#{target.class.name}##{method}:#{status} #{data.delete(:msg)}".strip
        payload = meta.merge(message: message, data: data)
        payload[:result] = data.delete(:result) if data.key?(:result)
        payload[:exception] = exception if exception
        Notification.publish(payload)
      end
    end
  end
end
