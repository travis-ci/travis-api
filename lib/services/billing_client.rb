module Services
  class BillingClient

    def update_address_request(subscription, address_data)
      @subscription = subscription
      response = connection(subscription_user_id).patch("/subscriptions/#{@subscription.id}/address", address_data)
      handle_subscription_response(response)
    end

    def csv_import(from, to, type)
      invoice_type = type == "refund" ? "&type=refunds" : ""
      response = connection_csv.get("/report?from=#{from}&to=#{to}#{invoice_type}")
      CSV.parse( response.body.gsub(/[\r\t]/, ''), col_sep: ',')
    end

    def v2_subscriptions(owner_id)
      response = connection_json(owner_id).get('/v2/subscriptions')
      handle_errors_and_respond_json(response) do |r|
        r.fetch('plans').map do |subscription_data|
          Travis::Models::Billing::V2Subscription.new(subscription_data.symbolize_keys)
        end
      end
    end

    def v2_subscription(owner_type, owner_id)
      response = connection_json('0').get("/#{owner_type}/#{owner_id}/get_plan")
      handle_errors_and_respond_json(response) do |r|
        Travis::Models::Billing::V2Subscription.new(r.symbolize_keys)
      end
    end

    def create_v2_subscription(owner_id, attributes)
      response = connection(owner_id).post('/v2/subscriptions', attributes)
      handle_errors_and_respond(response)
    end

    def update_v2_subscription(owner_id, id, attributes)
      response = connection(owner_id).patch("/v2/subscriptions/#{id}", attributes)
      handle_errors_and_respond(response)
    end

    def create_v2_addon(owner_id, id, attributes)
      response = connection(owner_id).patch("/v2/subscriptions/#{id}/addon", attributes)
      handle_errors_and_respond(response)
    end

    def update_auto_refill(owner_id, id, attributes)
      response = connection(owner_id).patch("/auto_refill", attributes)
      handle_errors_and_respond(response)
    end

    def v2_invoices(owner_id, sub_id)
      response = connection_json(owner_id).get("/v2/subscriptions/#{sub_id}/invoices")
      handle_errors_and_respond(response) { |r| r.map { |invoice_data| Travis::Models::Billing::Invoice.new(invoice_data) } }
    end

    def v2_plans(owner_id)
      response = connection_json(owner_id).get('/v2/plans_for/admin')
      handle_errors_and_respond_json(response) { |r| r.map { |plan_data| Travis::Models::Billing::V2PlanConfig.new(plan_data) } }
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
        raise JSON.parse(response.body)['error']
      end
    end

    def handle_errors_and_respond_json(response)
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

    def connection(id)
      @connection ||= Faraday.new(url: billing_url) do |conn|
        conn.basic_auth '_', billing_auth_key
        conn.headers['X-Travis-User-Id'] = id
        conn.headers['X-Travis-Source'] = 'admin'
        conn.request :url_encoded
        conn.response :json, content_type: 'application/x-www-form-urlencoded'
        conn.adapter Faraday.default_adapter
      end
    end

    def connection_json(owner_id)
      @connection_json ||= Faraday.new(url: billing_url) do |conn|
        conn.basic_auth '_', billing_auth_key
        conn.headers['X-Travis-User-Id'] = owner_id
        conn.headers['X-Travis-Source'] = 'admin'
        conn.headers['Content-Type'] = 'application/json'
        conn.request :json
        conn.response :json
        conn.adapter Faraday.default_adapter
      end
    end

    def connection_csv
      @connection_csv ||= Faraday.new(url: billing_url) do |conn|
        conn.headers['Authorization'] = "Token token=#{billing_auth_key}"
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

    def subscription_user_id
      (@subscription.owner_type == 'User') ? @subscription.owner.id.to_s : @subscription.owner.users.first.id.to_s
    end
  end
end
