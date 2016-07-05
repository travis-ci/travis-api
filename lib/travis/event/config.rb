require 'travis/secure_config'

module Travis
  module Event
    class Config
      DEFAULTS = {
        start:   { email: false,   webhooks: false,   campfire: false,   hipchat: false,   irc: false,   flowdock: false, sqwiggle: false, slack: false, pushover: false },
        success: { email: :change, webhooks: :always, campfire: :always, hipchat: :always, irc: :always, flowdock: :always, sqwiggle: :always, slack: :always, pushover: :always, },
        failure: { email: :always, webhooks: :always, campfire: :always, hipchat: :always, irc: :always, flowdock: :always, sqwiggle: :always, slack: :always, pushover: :always, }
      }

      attr_reader :payload, :build, :secure_key, :config

      def initialize(payload, secure_key = nil)
        @payload = payload
        @build = payload['build']
        @config = build['config']
        @secure_key = secure_key
      end

      def enabled?(key)
        return !!notifications[key] if notifications.has_key?(key) # TODO this seems inconsistent. what if email: { disabled: true }
        [:disabled, :disable].each { |key| return !notifications[key] if notifications.has_key?(key) } # TODO deprecate disabled and disable
        true
      end

      def send_on?(type, event)
        send(:"send_on_#{event}_for?", type)
      end

      def send_on_started_for?(type)
        config = with_fallbacks(type, :on_start, DEFAULTS[:start][type])
        config == true || config == :always
      end

      def send_on_finished_for?(type)
        send_on_initial_build? || send_on_success_for?(type) || send_on_failure_for?(type)
      end

      def send_on_initial_build?
        build['previous_state'].nil?
      end

      def send_on_success_for?(type)
        !!if build_passed?
          config = with_fallbacks(type, :on_success, DEFAULTS[:success][type])
          config == :always || (config == :change && !previous_build_passed?)
        end
      end

      def send_on_failure_for?(type)
        !!if !build_passed?
          config = with_fallbacks(type, :on_failure, DEFAULTS[:failure][type])
          config == :always || (config == :change && previous_build_passed?)
        end
      end

      def build_passed?
        build['state'].try(:to_sym) == :passed
      end

      def previous_build_passed?
        build['previous_state'].try(:to_sym) == :passed
      end

      # Fetches config with fallbacks. (notification type > global > default)
      # Filters can be configured for each notification type.
      # If no rules are configured for the given type, then fall back to the global rules, and then to the defaults.
      def with_fallbacks(type, key, default)
        config = if (notifications[type] && notifications[type].is_a?(Hash) && notifications[type].has_key?(key))
          # Returns the type config if key is present (notifications: email: [:on_success])
          notifications[type][key]
        elsif notifications.has_key?(key)
          # Returns the global config if key is present (notifications: [:on_success])
          notifications[key]
        else
          # Else, returns the given default
          default
        end

        config.respond_to?(:to_sym) ? config.to_sym : config
      end

      # Returns (recipients, urls, channels) for (email, webhooks, irc)
      # Notification type config can be nil, true/false, a string, an array of values,
      # or a hash containing a key for these values.
      def notification_values(type, key)
        config = notifications[type] rescue {}
        value  = config.is_a?(Hash) ? config[key] : config
        case value
        when Array, String
          normalize_array(value)
        else
          value
        end
      end

      def notifications
        Travis::SecureConfig.decrypt(config.fetch(:notifications, {}), secure_key)
      end

      def normalize_array(values)
        values = Array(values).compact
        values = values.map { |value| value.split(',') if value.is_a?(String) }
        values.compact.flatten.map(&:strip).reject(&:blank?)
      end
    end
  end
end
