describe Travis::API::V3::Services::BuildPermissions::UpdateForOrganization, set_app: true do
  let(:organization) { FactoryBot.create(:org_v3) }
  let(:user) { FactoryBot.create(:user, login: 'pavel-d') }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) { { 'HTTP_AUTHORIZATION'  =>  "token #{token}" } }


  before { stub_request(:patch, %r((.+)/org/(.+)/repos)).to_return(status: 200) }

  context 'not authenticated' do
    it 'returns access error' do
      patch("/v3/org/#{organization.id}/build_permissions", { user_ids: [user.id], permission: false })
      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    context 'user is an admin' do
      before { organization.memberships.create(user: user, role: 'admin', build_permission: true) }

      it 'updates build permissions' do
        patch("/v3/org/#{organization.id}/build_permissions", { user_ids: [user.id], permission: false }, headers)

        expect(last_response.status).to eq(204)
        expect(organization.memberships.first.build_permission).to eq(false)
      end
    end

    context 'user is a member' do
      before { organization.memberships.create(user: user, role: 'member', build_permission: true) }

      it 'returns access error' do
        patch("/v3/org/#{organization.id}/build_permissions", { user_ids: [user.id], permission: false }, headers)

        expect(last_response.status).to eq(403)
      end
    end
  end
end
