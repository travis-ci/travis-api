module Travis::API::V3
  class Services::EnterpriseLicense::Seat < Service

    MSGS = {
      exceeded: 'Enterprise account %s has exceeded seats.',
      api_endpoint_error: 'Replicated License API endpoint not found.'
    }

    def run!
      logger.warn MSGS[:exceeded] % [owner.login] and return false if enterprise? and replicated.license_seat_exceed?
    end

    class Replicated < Struct.new(:config)
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def license_seat_exceed?
        return true unless endpoint
        query.active_users > seats
      end

      def seats
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
        logger.warn MSGS[:api_endpoint_error] and return false unless endpoint
        # We turn off verification because this is an internal IP and a self signed cert so it will always fail
        @client ||= Faraday.new(endpoint, ssl: Travis::Gatekeeper.config.ssl.to_h.merge(verify: false)) do |client|
            client.adapter :net_http
        end
      end

      def endpoint
        Travis.config.replicated.endpoint
      end
    end

    private

    def replicated
      @replicated ||= Replicated.new(Travis.config)
      logger.warn MSGS[:api_endpoint_error] unless @replicated.endpoint
      @replicated
    end

    def enterprise?
      Travis.config.enterprise?
    end

    def owner
      repo.owner
    end
  end
end
