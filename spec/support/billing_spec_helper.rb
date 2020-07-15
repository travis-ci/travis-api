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
        "addons" => billing_addons_response_body,
        "source" => "manual",
        "status" => "",
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

    def billing_addons_response_body(attributes={})
      {
        "addons" => [
          {
            "id" => "1",
            "plan_id" => "1",
            "name" => "OSS Build Credits",
            "addon_type" => "credit_public",
            "created_at" => "2020-07-09T12:06:13.293Z",
            "updated_at" => "2020-07-09T12:07:03.619Z",
            "current_usage_id" => 1,
            "current_usage" => {
                "id" => 1,
                "addon_id" => 1,
                "addon_quantity" => 10000,
                "addon_usage" => 0,
                "purchase_date" => "2020-07-09T12:06:27.919Z",
                "valid_to" => nil,
                "status" => "active",
                "created_at" => "2020-07-09T12:06:27.944Z",
                "updated_at" => "2020-07-09T12:06:27.944Z"
            }
          },
          {
            "id" => 2,
            "plan_id" => 1,
            "name" => "Build Credits",
            "addon_type" => "credit_private",
            "created_at" => "2020-07-09T12:06:17.003Z",
            "updated_at" => "2020-07-09T12:07:09.067Z",
            "current_usage_id" => 2,
            "current_usage" => {
              "id" => 2,
              "addon_id" => 2,
              "addon_quantity" => 10000,
              "addon_usage" => 0,
              "purchase_date" => "2020-07-09T12:06:31.739Z",
              "valid_to" => nil,
              "status" => "active",
              "created_at" => "2020-07-09T12:06:31.741Z",
              "updated_at" => "2020-07-09T12:06:31.741Z"
            }
          }
        ]
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
