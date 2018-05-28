module Support
  module BillingSpecHelper
    def stub_billing_request(method, path, auth_key:, user_id:)
      url = URI(billing_url).tap do |url|
        url.path = path
      end.to_s
      stub_request(method, url).with(basic_auth: ['_', auth_key], headers: { 'X-Travis-User-Id' => user_id })
    end

    def billing_response_body(attributes={})
      {
        "permissions" => { "read" => true, "write" => true },
        "id" => 81,
        "valid_to" => "2017-11-28T00:09:59.502Z",
        "plan" => billing_plan_response_body,
        "coupon" => "",
        "status" => "canceled",
        "source" => "stripe",
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
  end
end
