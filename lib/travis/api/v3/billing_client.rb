module Travis::API::V3
  class BillingClient
    class ConfigurationError < StandardError; end

    ALLOWANCE_TIMEOUT = 1 # second

    def initialize(user_id)
      @user_id = user_id
    end

    def allowance(owner_type, owner_id)
      response = connection(timeout: ALLOWANCE_TIMEOUT).get("/usage/#{owner_type.downcase}s/#{owner_id}/allowance")
      return BillingClient.default_allowance_response unless response.status == 200

      Travis::API::V3::Models::Allowance.new(2, owner_id, response.body)
    end

    def authorize_build(repo, sender_id, jobs)
      response = connection.post("/#{repo.owner.class.name.downcase.pluralize}/#{repo.owner.id}/authorize_build", { repository: { private: repo.private? }, sender_id: sender_id, jobs: jobs })
      handle_errors_and_respond(response)
    end

    def self.default_allowance_response(id = 0)
      Travis::API::V3::Models::Allowance.new(1, id, {
        "public_repos" => true,
        "private_repos" => false,
        "concurrency_limit" => 1,
        "user_usage" => false,
        "pending_user_licenses" => false
      }.freeze)
    end

    def self.minimal_allowance_response(id = 0)
      Travis::API::V3::Models::Allowance.new(2, id, {})
    end

    def executions(owner_type, owner_id, page, per_page, from, to)
      response = connection.get("/usage/#{owner_type.downcase}s/#{owner_id}/executions?page=#{page}&per_page=#{per_page}&from=#{from}&to=#{to}")
      executions = response.body.map do |execution_data|
        Travis::API::V3::Models::Execution.new(execution_data)
      end
      executions
    end

    def all
      data = connection.get('/subscriptions').body
      subscriptions = data.fetch('subscriptions').map do |subscription_data|
        Travis::API::V3::Models::Subscription.new(subscription_data)
      end
      permissions = data.fetch('permissions')

      Travis::API::V3::Models::SubscriptionsCollection.new(subscriptions, permissions)
    end

    def all_v2
      data = connection.get('/v2/subscriptions').body
      subscriptions = data.fetch('plans').map do |subscription_data|
        Travis::API::V3::Models::V2Subscription.new(subscription_data)
      end
      permissions = data.fetch('permissions')

      Travis::API::V3::Models::SubscriptionsCollection.new(subscriptions, permissions)
    end

    def get_subscription(id)
      response = connection.get("/subscriptions/#{id}")
      handle_subscription_response(response)
    end

    def get_v2_subscription(id)
      response = connection.get("/v2/subscriptions/#{id}")
      handle_v2_subscription_response(response)
    end

    def get_invoices_for_subscription(id)
      connection.get("/subscriptions/#{id}/invoices").body.map do |invoice_data|
        Travis::API::V3::Models::Invoice.new(invoice_data)
      end
    end

    def get_invoices_for_v2_subscription(id)
      connection.get("/v2/subscriptions/#{id}/invoices").body.map do |invoice_data|
        Travis::API::V3::Models::Invoice.new(invoice_data)
      end
    end

    def trials
      connection.get('/trials').body.map do | trial_data |
        Travis::API::V3::Models::Trial.new(trial_data)
      end
    end

    def create_trial(type, id)
      response = connection.post("/trials/#{type}/#{id}")
      handle_errors_and_respond(response)
    end

    def update_address(subscription_id, address_data)
      response = connection.patch("/subscriptions/#{subscription_id}/address", address_data)
      handle_subscription_response(response)
    end

    def update_v2_address(subscription_id, address_data)
      response = connection.patch("/v2/subscriptions/#{subscription_id}/address", address_data)
      handle_v2_subscription_response(response)
    end

    def update_creditcard(subscription_id, creditcard_token)
      response = connection.patch("/subscriptions/#{subscription_id}/creditcard", token: creditcard_token)
      handle_subscription_response(response)
    end

    def update_v2_creditcard(subscription_id, creditcard_token)
      response = connection.patch("/v2/subscriptions/#{subscription_id}/creditcard", token: creditcard_token)
      handle_v2_subscription_response(response)
    end

    def update_plan(subscription_id, plan_data)
      response = connection.patch("/subscriptions/#{subscription_id}/plan", plan_data)
      handle_subscription_response(response)
    end

    def create_subscription(subscription_data)
      response = connection.post('/subscriptions', subscription_data)
      handle_subscription_response(response)
    end

    def create_v2_subscription(subscription_data)
      response = connection.post('/v2/subscriptions', subscription_data)
      handle_v2_subscription_response(response)
    end

    def changetofree_v2_subscription(subscription_id, data)
      response = connection.patch("/v2/subscriptions/#{subscription_id}/changetofree", data)
      handle_v2_subscription_response(response)
    end

    def update_v2_subscription(subscription_id, plan_data)
      response = connection.patch("/v2/subscriptions/#{subscription_id}/plan", plan_data)
      handle_v2_subscription_response(response)
    end

    def purchase_addon(subscription_id, addon_config_id)
      response = connection.patch("/v2/subscriptions/#{subscription_id}/addon", { addon: addon_config_id })
      handle_v2_subscription_response(response)
    end

    def v2_subscription_user_usages(subscription_id)
      connection.get("/v2/subscriptions/#{subscription_id}/user_usage").body.map do |usage_data|
        Travis::API::V3::Models::V2AddonUsage.new(usage_data)
      end
    end

    def v2_plans_for_organization(organization_id)
      connection.get("/v2/plans_for/organization/#{organization_id}").body.map do |plan_data|
        Travis::API::V3::Models::V2PlanConfig.new(plan_data)
      end
    end

    def v2_plans_for_user
      connection.get('/v2/plans_for/user').body.map do |plan_data|
        Travis::API::V3::Models::V2PlanConfig.new(plan_data)
      end
    end

    def cancel_subscription(id, reason_data)
      response = connection.post("/subscriptions/#{id}/cancel", reason_data)
      handle_subscription_response(response)
    end

    def plans_for_organization(organization_id)
      connection.get("/plans_for/organization/#{organization_id}").body.map do |plan_data|
        Travis::API::V3::Models::Plan.new(plan_data)
      end
    end

    def plans_for_user
      connection.get('/plans_for/user').body.map do |plan_data|
        Travis::API::V3::Models::Plan.new(plan_data)
      end
    end

    def resubscribe(id)
      response = connection.patch("/subscriptions/#{id}/resubscribe")
      handle_subscription_response(response)
    end

    def pay(id)
      response = connection.post("/subscriptions/#{id}/pay")
      handle_subscription_response(response)
    end

    def pay_v2(id)
      response = connection.post("/v2/subscriptions/#{id}/pay")
      handle_v2_subscription_response(response)
    end

    def get_coupon(code)
      response = connection.get("/coupons/#{code}")
      handle_coupon_response(response)
    end

    def update_organization_billing_permission(organization_id, billing_admin_only)
      response = connection.patch("/organization/permission_update/#{organization_id}", billing_admin_only)
      handle_subscription_response(response)
    end

    private

    def handle_subscription_response(response)
      handle_errors_and_respond(response) { |r| Travis::API::V3::Models::Subscription.new(r) }
    end

    def handle_v2_subscription_response(response)
      handle_errors_and_respond(response) { |r| Travis::API::V3::Models::V2Subscription.new(r) }
    end

    def handle_coupon_response(response)
      handle_errors_and_respond(response) { |r| Travis::API::V3::Models::Coupon.new(r) }
    end

    def handle_errors_and_respond(response)
      case response.status
      when 200, 201
        yield(response.body) if block_given?
      when 202
        true
      when 204
        true
      when 400
        raise Travis::API::V3::ClientError, response.body['error']
      when 403
        raise Travis::API::V3::InsufficientAccess, response.body['rejection_code']
      when 404
        raise Travis::API::V3::NotFound, response.body['error']
      when 422
        raise Travis::API::V3::UnprocessableEntity, response.body['error']
      else
        raise Travis::API::V3::ServerError, 'Billing system failed'
      end
    end

    def connection(timeout: 10)
      @connection ||= Faraday.new(url: billing_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
        conn.basic_auth '_', billing_auth_key
        conn.headers['X-Travis-User-Id'] = @user_id.to_s
        conn.headers['Content-Type'] = 'application/json'
        conn.request :json
        conn.response :json
        conn.options[:open_timeout] = timeout
        conn.options[:timeout] = timeout
        conn.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
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
