module Travis::API::V3
  class Billing
    class Error < StandardError; end
    class ConfigurationError < Error; end
    class NotFoundError < Error; end

    def initialize(user_id)
      @user_id = user_id
    end

    def get_subscription(id)
      response = connection.get("/subscriptions/#{id}")
      if response.success?
        Subscription.new(response.body)
      else
        raise NotFoundError, "Subscription ##{id} not found (HTTP Status: #{response.status})"
      end
    end

    private

    def connection
      @connection ||= Faraday.new(url: billing_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
        conn.basic_auth '_', billing_auth_key
        conn.headers['X-Travis-User-Id'] = @user_id.to_s
        conn.headers['Content-Type'] = 'application/json'
        conn.response :json
        conn.adapter :net_http
      end
    end

    def billing_url
      Travis.config.billing.url || raise(ConfigurationError, 'No billing url configured')
    end

    def billing_auth_key
      Travis.config.billing.auth_key || raise(ConfigurationError, 'No billing auth key configured')
    end

    class Subscription < Struct.new(:id)
      def initialize(attributes = {})
        super(attributes.fetch('id'))
      end
    end
  end
end
