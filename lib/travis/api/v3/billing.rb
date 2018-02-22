module Travis::API::V3
  class Billing
    attr_reader :user_id, :subscription

    def initialize(user_id = nil, subscription_id = nil)
      @user_id = user_id
      @subscription_id   = subscription_id
    end

    def create_subscription(subscription_params)
      post('/subscriptions', {user_id: user_id, subscription: subscription_params})
    end

    def cancel_subscription
      post("/subscriptions/#{subscription_id}/cancel", {user_id: user_id})
    end

    def edit_address(address)
      patch("/subscriptions/#{subscription_id}/address", {user_id: user_id, address: address})
    end

    def patch(url, payload)
      connect.patch do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.body = payload
      end
    end

    def post(url, payload)
      connect.post do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.body = payload
      end
    end

    def connect
      return unless billing_url && billing_auth_key
      @connect ||= Faraday.new(billing_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |client|
        client.basic_auth 'admin', billing_auth_key
        client.adapter :net_http
      end
    end

    def billing_url
      Travis.config.billing.url
    end

    def billing_auth_key
      ENV['BILLING_AUTH_KEY']
    end
  end
end
