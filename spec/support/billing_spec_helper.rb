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
        "cancellation_requested" => false,
        'current_trial' => nil,
        'on_trial_period' => false,
        "billing_info" => {
          "first_name" => "ana",
          "last_name" => "rosas",
          "company" => "",
          "billing_email" => "a.rosas10@gmail.com",
          'has_local_registration' => nil,
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
        'status' => nil,
        'valid_to' => nil,
        'canceled_at' => nil,
        "scheduled_plan" => nil,
        "cancellation_requested" => false,
        "plan_config" => {
          'id' => 'pro_tier_plan',
          'name' => 'Pro Tier Plan',
          'plan_type' => 'metered',
          'concurrency_limit' => 20,
          'private_repos' => true,
          'starting_price' => 30000,
          'starting_users' => 10000,
          'private_credits' => 500000,
          'public_credits' => 40000,
          'annual' => false,
          'auto_refill_thresholds' => [10000, 50000, 100000],
          'auto_refill_amounts' => [
            {
              'amount' => 25000,
              'price' => 1500
            },
            {
              'amount' => 100000,
              'price' => 6000
            },
            {
              'amount' => 200000,
              'price' => 6000
            },
            {
              'amount' => 400000,
              'price' => 12000
            }
          ],
          'available_standalone_addons' => [
            {
              'id' => 'credits_25k',
              'name' => '25 000 credits (2,5k Linux build minutes)',
              'price' => 1500,
              'quantity' => 25000,
              'type' => 'credit_private'
            },
            {
              'id' => 'credits_500k',
              'name' => '500 000 credits (50k Linux build minutes)',
              'price' => 30000,
              'quantity' => 500000,
              'type' => 'credit_private'
            }
          ],
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
          "recurring" => false,
          "current_usage" => {
              "id" => 1,
              "addon_id" => 1,
              "addon_quantity" => 40000,
              "addon_usage" => 0,
              "remaining" => 40000,
              "purchase_date" => "2017-11-28T00:09:59.502Z",
              "valid_to" => "2017-12-28T00:09:59.502Z",
              "status" => "subscribed",
              "active" => true
          }
        },
        {
          "id" => 2,
          "name" => "Build Credits",
          "type" => "credit_private",
          "recurring" => false,
          "current_usage" => {
            "id" => 2,
            "addon_id" => 2,
            "addon_quantity" => 10000,
            "addon_usage" => 0,
            "remaining" => 10000,
            "purchase_date" => "2017-11-28T00:09:59.502Z",
            "valid_to" => "",
            "status" => "subscribed",
            "active" => true
          }
        }
      ]
    end

    def billing_addon_usage_response_body(attributes = {})
      {
        'id' => 1,
        'addon_id' => 1,
        'addon_quantity' => 100,
        'addon_usage' => 0,
        'remaining' => 100,
        'purchase_date' => '2020-09-14T11:25:02.612Z',
        'valid_to' => '2020-10-14T11:25:02.612Z',
        'status' => 'subscribed',
        'active' => true,
        'created_at' => '2020-09-14T11:25:02.614Z',
        'updated_at' => '2020-09-14T11:25:02.614Z'
      }.deep_merge(attributes)
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

    def billing_v2_plan_response_body(attributes = {})
      {
        'id' => 'free_tier_plan',
        'name' => 'Free Tier Plan',
        'private_repos' => true,
        'plan_type' => 'metered',
        'concurrency_limit' => 20,
        'addon_configs' => [
          {
            'id' => 'oss_tier_credits',
            'name' => 'Free 40 000 credits (renewed monthly)',
            'price' => 0,
            'quantity' => 40_000,
            'type' => 'credit_public'
          },
          {
            'id' => 'free_tier_credits',
            'name' => 'Free 10 000 credits (renewed monthly)',
            'price' => 0,
            'quantity' => 10_000,
            'type' => 'credit_private'
          },
          {
            'id' => 'users_free',
            'name' => 'Unlimited users',
            'price' => 0,
            'quantity' => 999_999,
            'type' => 'user_license'
          }
        ],
        'starting_price' => 0,
        'starting_users' => 999_999,
        'private_credits' => 10_000,
        'public_credits' => 40_000,
        'annual' => false,
        'auto_refill_thresholds' => [10000, 50000, 100000],
        'auto_refill_amounts' => [
          {
            'amount' => 25000,
            'price' => 1500
          },
          {
            'amount' => 100000,
            'price' => 6000
          },
          {
            'amount' => 200000,
            'price' => 6000
          },
          {
            'amount' => 400000,
            'price' => 12000
          }
        ],
        'available_standalone_addons' => []
      }.deep_merge(attributes)
    end

    def billing_v2_credits_calculator_body
      [
        {
          'users' => 3,
          'minutes' => nil,
          'os' => nil,
          'instance_size' => nil,
          'credits' => 25_000,
          'price' => 1_500
        },
        {
          'users' => nil,
          'minutes' => 1000,
          'os' => 'linux',
          'instance_size' => '2x-large',
          'credits' => 250_000,
          'price' => 15_000
        }
      ]
    end

    def billing_v2_credits_calculator_config_body
      {
        'users' => 10,
        'minutes' => 1000,
        'os' => 'linux',
        'instance_size' => '2x-large'
      }
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

    def billing_executions_response_body(attributes = {})
      {
        'id' => 1,
        'os' => 'linux',
        'instance_size' => 'standard-2',
        'arch' => 'amd64',
        'virtualization_type' => 'vm',
        'queue' => 'builds.gce-oss',
        'job_id' => 123,
        'repository_id' => 1,
        'owner_id' => 1,
        'owner_type' => 'User',
        'plan_id' => 2,
        'sender_id' => 1,
        'credits_consumed' => 5,
        'user_license_credits_consumed' => 4,
        'started_at' => Time.now.utc.iso8601,
        'finished_at' => (Time.now. + 10.minutes).utc.iso8601,
        'created_at' => Time.now.utc.iso8601,
        'updated_at' => Time.now.utc.iso8601
      }.deep_merge(attributes)
    end

    def billing_executions_multiple_response_body(attributes = {})
      [{
        'id' => 1,
        'os' => 'linux',
        'instance_size' => 'standard-2',
        'arch' => 'amd64',
        'virtualization_type' => 'vm',
        'queue' => 'builds.gce-oss',
        'job_id' => 123,
        'repository_id' => 1,
        'owner_id' => 1,
        'owner_type' => 'User',
        'plan_id' => 2,
        'sender_id' => 1,
        'credits_consumed' => 5,
        'user_license_credits_consumed' => 4,
        'started_at' => Time.now.utc.iso8601,
        'finished_at' => (Time.now. + 10.minutes).utc.iso8601,
        'created_at' => Time.now.utc.iso8601,
        'updated_at' => Time.now.utc.iso8601
      }.deep_merge(attributes),
      {
        'id' => 2,
        'os' => 'linux',
        'instance_size' => 'standard-2',
        'arch' => 'amd64',
        'virtualization_type' => 'vm',
        'queue' => 'builds.gce-oss',
        'job_id' => 123,
        'repository_id' => 1,
        'owner_id' => 1,
        'owner_type' => 'User',
        'plan_id' => 2,
        'sender_id' => 0,
        'credits_consumed' => 5,
        'user_license_credits_consumed' => 4,
        'started_at' => Time.now.utc.iso8601,
        'finished_at' => (Time.now. + 10.minutes).utc.iso8601,
        'created_at' => Time.now.utc.iso8601,
        'updated_at' => Time.now.utc.iso8601
      }]
    end
  end
end
