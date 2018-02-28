require 'spec_helper'
describe Travis::API::V3::Services::Subscription::Create, set_app: true do
  let(:user) { Travis::API::V3::Models::User.create(login: 'example-user', github_id: 1234) }
  let(:subscription_payload) {{
    'subscription' =>
      { 'owner_id'   => user.id,
        'selected_plan' => 'travis-ci-two-builds',
        'address'     => 'Rigaer St 8'}
    }}
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }

  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}", "Content-Type" => "application/json" }}

  before do
    Travis.config.billing = {url:'https://billing-v2-test.travis-ci.com'}
    ENV['BILLING_AUTH_KEY'] = 'abc123'
  end

  describe 'create subscription' do
    before do
      Travis::API::V3::Billing.any_instance.stubs(:create_subscription).returns({'id' => '111', 'owner_id' => '111', 'selected_plan' => 'travis-ci-two-builds'})

      post("/v3/subscription", subscription_payload, headers)
    end

    example { expect(last_response.status).to be 201 }
  end

end
