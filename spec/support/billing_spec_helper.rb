module BillingSpecHelper
  def billing_response_body(attributes={})
    {
    "id" => 81,
    "valid_to" => "2017-11-28T00:09:59.502Z",
    "plan" => "travis-ci-ten-builds",
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
      "country" => "Mexico"
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
  }.merge attributes
  end
end
