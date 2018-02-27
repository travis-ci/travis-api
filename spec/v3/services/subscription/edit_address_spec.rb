require 'spec_helper'
describe Travis::API::V3::Services::Subscription::Create, set_app: true do
  let(:user) { Travis::API::V3::Models::User.create(login: 'example-user', github_id: 1234) }
  let(:valid_to) { Time.now.utc + 1.month }
  let(:subscription) { Travis::API::V3::Models::Subscription.create(owner: user, valid_to: valid_to,source: "stripe", status: "subscribed", selected_plan: "travis-ci-two-builds") }
  let(:address_payload) { {
      'address' => {
        'address' => 'Rigaer Strasse 8',
        'address2' => nil,
        'city' => 'Berlin',
        'state' => nil,
        'country' => 'DE'
      }
  } }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }

  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}", "Content-Type" => "application/json" }}

  before do
    Travis.config.billing = {url:'https://billing-v2-test.travis-ci.com'}
    ENV['BILLING_AUTH_KEY'] = 'abc123'
  end

  describe 'edit subscription address' do
    before do
      Travis::API::V3::Billing.any_instance.stubs(:edit_address).returns({body: {id: '111'}, status: 200})

      patch("/v3/subscription/#{subscription.id}/edit_address", address_payload, headers)
    end
    example { expect(last_response).to be_ok   }
    example { expect(last_response.status).to be 201 }
  end

end
