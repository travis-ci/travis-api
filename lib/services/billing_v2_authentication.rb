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

    # def csv_data(from, to invoice_type)
    #   response = connection.patch("/report?from=#{from}&to=#{to}" + invoice_type)
    #   handle_subscription_response(response)
    # end

    def billing_url
      travis_config.billing.url || raise(ConfigurationError, 'No billing url configured')
    end

    def billing_auth_key
      travis_config.billing.auth_key || raise(ConfigurationError, 'No billing auth key configured')
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
      # binding.pry
      @connection ||= Faraday.new(url: billing_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
        conn.basic_auth '_', billing_auth_key
        conn.headers['X-Travis-User-Id'] = @subscription.owner_id.to_s
        conn.headers['Content-Type'] = 'application/json'
        conn.request :json
        conn.response :json
        conn.adapter :net_http
      end
    end

    # def billing_url
    #   travis_config.billing.url || raise(ConfigurationError, 'No billing url configured')
    # end
    #
    # def billing_auth_key
    #   travis_config.billing.auth_key || raise(ConfigurationError, 'No billing auth key configured')
    # end

    def travis_config
      TravisConfig.load
    end
  end
end
