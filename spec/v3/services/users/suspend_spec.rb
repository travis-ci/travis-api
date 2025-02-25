describe Travis::API::V3::Services::Organization::Suspend, set_app: true do
  let(:organization_id) { 1 }
  let(:organization) { FactoryBot.create(:org) }

  context 'unauthenticated' do
    it 'responds 403' do
      post("/v3/users/suspend",JSON.generate({user_ids: [1,2,3]}))
      expect(last_response.status).to eq(403)
    end
  end

  describe 'authenticated' do
    let(:internal_token) { 'FOO' }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "internal admin:#{internal_token}", 'CONTENT_TYPE' => 'application/json' } }
    around do |ex|
      apps = Travis.config.applications
      Travis.config.applications = { 'admin' => { token: internal_token, full_access: true }}
      ex.run
      Travis.config.applications = apps
    end
    let(:user_to_suspend) { FactoryBot.create(:user, vcs_id: 100, vcs_type: 'GithubUser') }
    let(:another_user_to_suspend) { FactoryBot.create(:user, vcs_id: 101, vcs_type: 'GithubUser') }
    it 'suspends the users' do
      post("/v3/users/suspend",JSON.generate({user_ids: [user_to_suspend.id, another_user_to_suspend.id]}),  headers)
      expect(last_response.status).to eq(200)
      expect(user_to_suspend.suspended)
      expect(another_user_to_suspend.suspended)
      post("/v3/users/unsuspend", JSON.generate({user_ids: [user_to_suspend.id]}), headers)
      expect(!user_to_suspend.suspended)
      expect(another_user_to_suspend.suspended)
    end

    it 'suspends the users by vcs_id' do
      post("/v3/users/suspend",JSON.generate({vcs_ids: [user_to_suspend.vcs_id, another_user_to_suspend.vcs_id], vcs_type: 'github'}),  headers)
      expect(last_response.status).to eq(200)
      expect(user_to_suspend.suspended)
      expect(another_user_to_suspend.suspended)
      post("/v3/users/unsuspend", JSON.generate({vcs_ids: [user_to_suspend.vcs_id], vcs_type: 'GithubUser'}), headers)
      expect(!user_to_suspend.suspended)
      expect(another_user_to_suspend.suspended)
    end
  end
end
