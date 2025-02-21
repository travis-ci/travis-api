describe Travis::API::V3::Services::Organization::UserActivity, set_app: true do
  let(:organization_id) { 1 }
  let(:organization) { FactoryBot.create(:org) }

  context 'unauthenticated' do
    it 'responds 403' do
      get("/v3/org/#{organization.id}/user_activity")
      expect(last_response.status).to eq(403)
    end
  end

  describe 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:another_user) { FactoryBot.create(:user) }
    let(:token) { Travis::API::V3::Models::OrganizationToken.create(organization: organization, token: "#{organization.id}:toktok") }
    let!(:token_perms) { Travis::API::V3::Models::OrganizationTokenPermission.create(organization_token: token, permission: 'activity') }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "org.token #{token.token}",
                     'CONTENT_TYPE' => 'application/json' }}

    context 'user has a proper token' do
      before do
        organization.memberships.create(user: user, role: 'admin')
        organization.memberships.create(user: another_user, role: 'member')
      end
      it 'gets active users' do
        get("/v3/org/#{organization.id}/user_activity",nil, headers)
        expect(last_response.status).to eq(200)
      end
    end

    context 'a token with wrong scope is used' do
      before { token_perms.update!(permission: 'suspend') }
      it 'returns 403 error' do
        get("/v3/org/#{organization.id}/user_activity",nil, headers)
        expect(last_response.status).to eq(403)
      end
    end
  end
end
