module Services
  class Billing_v2_authentication
    attr_reader :subscription

    def initialize(subscription)
      @subscription = subscription
    end

    def update_address(subscription_id, address_data)
      response = connection.patch("/subscriptions/#{subscription_id}/address", address_data)
      handle_subscription_response(response)
    end

    private

    def handle_subscription_response(response)
      handle_errors_and_respond(response) { |r| Subscription.new(r) }
    end

    def handle_errors_and_respond(response)
      case response.status
      when 200, 201
        yield(response.body) if block_given?
      when 202
        true
      when 204
        true
      else
        raise response.body['error']
      end
    end

    def connection
      @connection ||= Faraday.new(url: billing_url) do |conn|
        conn.basic_auth '_', billing_auth_key
        conn.headers['X-Travis-User-Id'] = @subscription.owner_id.to_s
        conn.request :url_encoded
        conn.response :json, content_type: 'application/x-www-form-urlencoded'
        conn.adapter Faraday.default_adapter
      end
    end

    def billing_url
      travis_config.billing.url || raise(ConfigurationError, 'No billing url configured')
    end

    def billing_auth_key
      travis_config.billing.auth_key || raise(ConfigurationError, 'No billing auth key configured')
    end

    def travis_config
      TravisConfig.load
    end
  end
end
