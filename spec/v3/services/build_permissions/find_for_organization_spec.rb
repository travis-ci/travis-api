describe Travis::API::V3::Services::BuildPermissions::FindForOrganization, set_app: true do
  let(:organization) { FactoryBot.create(:org_v3) }
  let(:user) { FactoryBot.create(:user, login: 'pavel-d', vcs_type: 'GithubUser') }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) { { 'HTTP_AUTHORIZATION'  =>  "token #{token}" } }

  before { organization.memberships.create(user: user, role: 'admin', build_permission: true) }

  context 'not authenticated' do
    it 'returns access error' do
      get("/v3/org/#{organization.id}/build_permissions")
      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    it 'returns build permissions' do
      get("/v3/org/#{organization.id}/build_permissions", {}, headers)

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['build_permissions'].first).to eq(
        {
          '@type' => 'build_permission',
          '@representation' => 'standard',
          'user' => {
            '@type' => 'user',
            '@href' => "/user/#{user.id}",
            '@representation' => 'minimal',
            'id' => user.id,
            'login' => user.login,
            'name' => user.name,
            'vcs_type' => 'GithubUser',
            'ro_mode' => false
          },
          'permission' => true,
          'role' => 'admin'
        }
      )
    end
  end
end
