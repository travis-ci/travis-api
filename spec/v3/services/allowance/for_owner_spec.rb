require 'spec_helper'

RSpec.describe Travis::API::V3::Services::Allowance::ForOwner, set_app: true, billing_spec_helper: true do
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }
  let(:json_headers) { { 'HTTP_ACCEPT' => 'application/json' } }
  let(:user_token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }

  before do
    Travis.config.host = 'travis-ci.com'
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user, name: 'Joe', login: 'joe') }
    let(:v2_response_body) { JSON.dump(allowance_data) }

    before do
      stub_billing_request(:get, "/usage/users/#{user.id}/allowance", auth_key: billing_auth_key, user_id: user.id)
      .to_return(status: 200, body: v2_response_body)
    end

    context 'when user has no plan' do
      let(:allowance_data) { {'no_plan' => true} }

      describe 'returns subscription_type=3' do
        before { get("/v3/owner/#{user.login}/allowance", {}, json_headers.merge('HTTP_AUTHORIZATION' => "token #{user_token}")) }

        example { expect(last_response).to be_ok }
        example { expect(JSON.parse(last_response.body)['subscription_type']).to eq(3) }
      end
    end

    context 'when user has a plan' do
      let(:allowance_data) { {'no_plan' => false} }

      describe 'returns subscription_type=3' do
        before { get("/v3/owner/#{user.login}/allowance", {}, json_headers.merge('HTTP_AUTHORIZATION' => "token #{user_token}")) }

        example { expect(last_response).to be_ok }
        example { expect(JSON.parse(last_response.body)['subscription_type']).to eq(2) }
      end
    end
  end
end
