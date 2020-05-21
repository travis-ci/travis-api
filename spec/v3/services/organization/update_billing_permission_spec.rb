describe Travis::API::V3::Services::Organization::UpdateBillingPermission, set_app: true, billing_spec_helper: true do
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }
  let(:organization_id) { rand(999) }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      patch("/v3/org/#{organization_id}/update_billing_permission", { })

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    let(:billing_admin_only) { { billing_admin_only: true } }


    let!(:stubbed_request) do
      stub_billing_request(:patch, "/organization/permission_update/#{organization_id}", auth_key: billing_auth_key, user_id: user.id)
        .with(body: JSON.dump(billing_admin_only))
        .to_return(status: 204)
    end

    it 'updates the billing permission on organization' do
      patch("/v3/org/#{organization_id}/update_billing_permission", JSON.generate(billing_admin_only), headers)

      expect(last_response.status).to eq(204)
      expect(stubbed_request).to have_been_made.once
    end
  end
end
