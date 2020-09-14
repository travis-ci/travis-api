module Support
  module BillingSpecHelper
    def stub_billing_request(method, path, auth_key:, user_id:)
      url = URI(billing_url).tap do |url|
        url.path = path
      end.to_s
      stub_request(method, url).with(basic_auth: ['_', auth_key], headers: { 'X-Travis-User-Id' => user_id })
    end

    def billing_subscription_response_body(attributes={})
      {
        "permissions" => { "read" => true, "write" => true },
        "id" => 81,
        "valid_to" => "2017-11-28T00:09:59.502Z",
        "plan" => billing_plan_response_body,
        "coupon" => "",
        "status" => "canceled",
        "source" => "stripe",
        "created_at" => "2017-11-28T00:09:59.502Z",
        "billing_info" => {
          "first_name" => "ana",
          "last_name" => "rosas",
          "company" => "",
          "billing_email" => "a.rosas10@gmail.com",
          "zip_code" => "28450",
          "address" => "Luis Spota",
          "address2" => "",
          "city" => "Comala",
          "state" => nil,
          "country" => "Mexico",
          "vat_id" => "123456"
        },
        "credit_card_info" => {
          "card_owner" => "ana",
          "last_digits" => "4242",
          "expiration_date" => "9/2021"
        },
        "discount" => billing_coupon_response_body,
        "owner" => {
          "type" => "Organization",
          "id" => 43
        }
      }.deep_merge(attributes)
    end

    def billing_v2_subscription_response_body(attributes={})
      {
        "permissions" => { "read" => true, "write" => true },
        "id" => 81,
        "plan_config" => {
          "id" => "pro_tier_plan",
          "name" => "Pro Tier Plan",
          'private_repos' => true,
          'starting_price' => 30000,
          'starting_users' => 10000,
          'private_credits' => 500000,
          'public_credits' => 40000,
          'addon_configs' => {
            'free_tier_credits' => {
              'name' => 'Free 10 000 credits (renewed monthly)',
              'expires' => true,
              'expires_in' => 1,
              'renew_after_expiration' => true,
              'price' => 0,
              'price_id' => 'price_1234567890',
              'price_type' => 'fixed',
              'quantity' => 10_000,
              'standalone' => false,
              'type' => 'credit_private',
              'available_for_plans' => '%w[free_tier_plan]'
            },
            'oss_tier_credits' => {
              'name' => 'Free 40 000 credits (renewed monthly)',
              'expires' => true,
              'expires_in' => 1,
              'renew_after_expiration' => true,
              'price' => 0,
              'price_id' => 'price_0987654321',
              'price_type' => 'fixed',
              'quantity' => 40_000,
              'standalone' => false,
              'type' => 'credit_public',
              'private_repos' => false,
              'available_for_plans' => '%w[free_tier_plan standard_tier_plan pro_tier_plan]'
            }
          }
        },
        "addons" => billing_addons_response_body,
        "source" => "stripe",
        "created_at" => "2017-11-28T00:09:59.502Z",
        "billing_info" => {
          "first_name" => "ana",
          "last_name" => "rosas",
          "company" => "",
          "billing_email" => "a.rosas10@gmail.com",
          "zip_code" => "28450",
          "address" => "Luis Spota",
          "address2" => "",
          "city" => "Comala",
          "state" => nil,
          "country" => "Mexico",
          "vat_id" => "123456"
        },
        "credit_card_info" => {
          "card_owner" => "ana",
          "last_digits" => "4242",
          "expiration_date" => "9/2021"
        },
        "owner" => {
          "type" => "Organization",
          "id" => 43
        }
      }.deep_merge(attributes)
    end

    def billing_addons_response_body
      [
        {
          "id" => "1",
          "name" => "OSS Build Credits",
          "type" => "credit_public",
          "current_usage" => {
              "id" => 1,
              "addon_id" => 1,
              "addon_quantity" => 40000,
              "addon_usage" => 0,
              "remaining" => 40000,
              "active" => true
          }
        },
        {
          "id" => 2,
          "name" => "Build Credits",
          "type" => "credit_private",
          "current_usage" => {
            "id" => 2,
            "addon_id" => 2,
            "addon_quantity" => 10000,
            "addon_usage" => 0,
            "remaining" => 10000,
            "active" => true
          }
        }
      ]
    end

    def billing_plan_response_body(attributes={})
      {
        "id" => "travis-ci-ten-builds",
        "name" => "Startup",
        "builds" => 10,
        "annual" => false,
        "price" => 12500,
        "currency" => "USD"
      }.deep_merge(attributes)
    end

    def billing_coupon_response_body(attributes = {})
      {
        "id" => "10_BUCKS_OFF",
        "name" => "10 bucks off!",
        "percent_off" => nil,
        "amount_off" => 1000,
        "valid" => true,
        "duration" => 'repeating',
        "duration_in_months" => 3
      }.deep_merge(attributes)
    end

    def billing_trial_response_body(attributes = {})
      {
        'id' => 456,
        'permissions' => { 'read' => true, 'write' => true },
        'owner' => {
          'type' => 'Organization',
          'id' => 43
        },
        'created_at' => Time.now,
        'status' => 'started',
        'builds_remaining' => 5
      }.deep_merge(attributes)
    end
  end
end
