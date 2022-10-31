describe Travis::API::V3::Services::BuildPermissions::FindForRepo, set_app: true do
  let(:repository) { FactoryBot.create(:repository) }
  let(:user) { FactoryBot.create(:user, login: 'pavel-d', vcs_type: 'GithubUser') }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) { { 'HTTP_AUTHORIZATION'  =>  "token #{token}" } }

  before { FactoryBot.create(:permission, user: user, repository: repository, build: true) }

  context 'not authenticated' do
    it 'returns access error' do
      get("/v3/repo/#{repository.id}/build_permissions")
      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    it 'returns build permissions' do
      get("/v3/repo/#{repository.id}/build_permissions", {}, headers)

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['build_permissions'].first).to eq(
        {
          "@type" => "build_permission",
          "@representation" => "standard",
          "user" => {
            "@type" => "user",
            "@href" => "/user/#{user.id}",
            "@representation" => "minimal",
            "id" => user.id,
            "login" => user.login,
            "name" => user.name,
            "vcs_type" => 'GithubUser',
            "ro_mode" => false
          },
          "permission" => true,
          "role" => nil
        }
      )
    end
  end
end
