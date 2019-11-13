require 'faraday'
require 'json'

module Travis
  class Enterprise
    class << self
    MSGS = {
      exceeded: 'Enterprise account has exceeded seats.',
      api_endpoint_error: 'Replicated License API endpoint not found.'
    }

    def check_license_seat?
      Travis.logger.warn MSGS[:exceeded] and return true if enterprise? and replicated.license_seat_exceed?
      return false
    end

    def allocated_license_seats
      replicated.seats if enterprise?
    end

    class Replicated < Struct.new(:config)
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def license_seat_exceed?
        return true unless endpoint
        active_users.size >= seats
      end

      def active_users
        User.where('github_oauth_token IS NOT NULL AND suspended=false')
      end

      def seats
        return true unless endpoint
        data = YAML.load(te_license['value'])
        data['production']['license']['seats']
      end

      def te_license
        license['fields'].find { |fields| fields['field'] == 'te_license' }
      end

      def license
        return false unless client
        @license ||= client.get('license/v1/license')
        JSON.parse(@license.body)
      end

      def client
        Travis.logger.warn MSGS[:api_endpoint_error] and return false unless endpoint
        # We turn off verification because this is an internal IP and a self signed cert so it will always fail
        @client ||= Faraday.new(endpoint, ssl: Travis.config.ssl.to_h.merge(verify: false)) do |client|
            client.adapter :net_http
        end
      end

      def endpoint
        Travis.config.replicated.endpoint
      end
    end

    private

      def replicated
        @replicated = Replicated.new(Travis.config)
        Travis.logger.warn MSGS[:api_endpoint_error] unless @replicated.endpoint
        @replicated
      end

      def enterprise?
        Travis.config.enterprise?
      end
  end
end
end
