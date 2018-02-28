require 'spec_helper'
describe Travis::API::V3::Services::Subscription::Create, set_app: true do
  let(:user) { Travis::API::V3::Models::User.create(login: 'example-user', github_id: 1234) }
  let(:valid_to) { Time.now.utc + 1.month }
  let(:subscription) { Travis::API::V3::Models::Subscription.create(owner: user, valid_to: valid_to,source: "stripe", status: "subscribed", selected_plan: "travis-ci-two-builds") }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }

  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}", "Content-Type" => "application/json" }}

  before do
    Travis.config.billing = {url:'https://billing-v2-test.travis-ci.com'}
    ENV['BILLING_AUTH_KEY'] = 'abc123'
  end

  describe 'cancel existing subscription' do
    before do
      Travis::API::V3::Billing.any_instance.stubs(:cancel_subscription).returns({body: {id: '111'}, status: 202})

      post("/v3/subscription/#{subscription.id}/cancel", {}, headers)
    end

    example { expect(last_response.status).to be 202 }
  end

end
