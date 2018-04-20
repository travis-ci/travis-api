module Travis::API::V3
  class BillingClient
    class ConfigurationError < StandardError; end

    def initialize(user_id)
      @user_id = user_id
    end

    def all
      connection.get('/subscriptions').body.map do |subscription_data|
        Travis::API::V3::Models::Subscription.new(subscription_data)
      end
    end

    def get_subscription(id)
      response = connection.get("/subscriptions/#{id}")
      handle_errors_and_respond(response)
    end

    def get_invoices_for_subscription(id)
      connection.get("/subscriptions/#{id}/invoices").body.map do |invoice_data|
        Travis::API::V3::Models::Invoice.new(invoice_data)
      end
    end

    def update_address(subscription_id, address_data)
      response = connection.patch("/subscriptions/#{subscription_id}/address", address_data)
      handle_errors_and_respond(response)
    end

    def update_creditcard(subscription_id, creditcard_token)
      response = connection.patch("/subscriptions/#{subscription_id}/creditcard", token: creditcard_token)
      handle_errors_and_respond(response)
    end

    def update_plan(subscription_id, plan_data)
      response = connection.patch("/subscriptions/#{subscription_id}/plan", plan_data)
      handle_errors_and_respond(response)
    end

    def create_subscription(subscription_data)
      response = connection.post('/subscriptions', subscription_data)
      handle_errors_and_respond(response)
    end

    def cancel_subscription(id)
      response = connection.post("/subscriptions/#{id}/cancel")
      handle_errors_and_respond(response)
    end

    def plans
      connection.get('/plans').body.map do |plan_data|
        Travis::API::V3::Models::Plan.new(plan_data)
      end
    end

    private

    def handle_errors_and_respond(response)
      case response.status
      when 200, 201
        Travis::API::V3::Models::Subscription.new(response.body)
      when 204
        true
      when 404
        raise Travis::API::V3::NotFound, response.body['error']
      when 400
        raise Travis::API::V3::ClientError, response.body['error']
      when 422
        raise Travis::API::V3::UnprocessableEntity, response.body['error']
      else
        raise Travis::API::V3::ServerError, 'Billing system failed'
      end
    end

    def connection
      @connection ||= Faraday.new(url: billing_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
        conn.basic_auth '_', billing_auth_key
        conn.headers['X-Travis-User-Id'] = @user_id.to_s
        conn.headers['Content-Type'] = 'application/json'
        conn.request :json
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
  end
end
