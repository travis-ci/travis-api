describe Travis::API::V3::Services::Organization::Suspend, set_app: true do
  let(:organization_id) { 1 }
  let(:organization) { FactoryBot.create(:org) }

  context 'unauthenticated' do
    it 'responds 403' do
      post("/v3/org/#{organization_id}/suspend",JSON.generate({user_ids: [1,2,3]}))
      expect(last_response.status).to eq(403)
    end
  end


  describe 'authenticated org admin' do
    let(:user) { FactoryBot.create(:user, vcs_id: 100, vcs_type: 'GithubUser') }
    let(:user_to_suspend) { FactoryBot.create(:user, vcs_id: 101, vcs_type: 'GithubUser') }
    let(:another_user_to_suspend) { FactoryBot.create(:user, vcs_id: 102, vcs_type: 'GithubUser') }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    context 'user is admin' do
      before do
        organization.memberships.create(user: user, role: 'admin')
        organization.memberships.create(user: user_to_suspend, role: 'member')
        organization.memberships.create(user: another_user_to_suspend, role: 'member')
      end

      it 'has no rights to suspend the users' do
        post("/v3/org/#{organization_id}/suspend", JSON.generate({user_ids: [user_to_suspend.id, another_user_to_suspend.id]}), headers)
        expect(last_response.status).to eq(403)
        post("/v3/org/#{organization_id}/unsuspend", JSON.generate({user_ids: [user_to_suspend.id, another_user_to_suspend.id]}), headers)
        expect(last_response.status).to eq(403)

        post("/v3/org/#{organization_id}/suspend", JSON.generate({vcs_ids: [user_to_suspend.id, another_user_to_suspend.id], vcs_type: 'github'}), headers)
      end
    end
  end

  describe 'authenticated with proper org token' do

    let(:user) { FactoryBot.create(:user, vcs_id: 100, vcs_type: 'GithubUser') }
    let(:user_to_suspend) { FactoryBot.create(:user, vcs_id: 101, vcs_type: 'GithubUser') }
    let(:another_user_to_suspend) { FactoryBot.create(:user, vcs_id: 102, vcs_type: 'GithubUser') }
    let(:token) { Travis::API::V3::Models::OrganizationToken.create(organization: organization, token: "#{organization.id}:toktok") }
    let!(:token_perms) { Travis::API::V3::Models::OrganizationTokenPermission.create(organization_token: token, permission: 'suspend') }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "org.token #{token.token}",
                     'CONTENT_TYPE' => 'application/json' }}
    context 'proper org token is used' do
      it 'suspends the users' do
        post("/v3/org/#{organization_id}/suspend", JSON.generate({user_ids: [user_to_suspend.id, another_user_to_suspend.id]}), headers)
        expect(last_response.status).to eq(200)
        expect(user_to_suspend.suspended)
        expect(another_user_to_suspend.suspended)
        post("/v3/org/#{organization_id}/unsuspend", JSON.generate({user_ids: [user_to_suspend.id]}), headers)
        expect(!user_to_suspend.suspended)
        expect(another_user_to_suspend.suspended)
      end

      it 'suspends the users with vcs_id' do
        post("/v3/org/#{organization_id}/suspend", JSON.generate({vcs_ids: [user_to_suspend.vcs_id, another_user_to_suspend.vcs_id], vcs_type: 'github'}), headers)
        expect(last_response.status).to eq(200)
        expect(user_to_suspend.suspended)
        expect(another_user_to_suspend.suspended)
        post("/v3/org/#{organization_id}/unsuspend", JSON.generate({vcs_ids: [user_to_suspend.vcs_id], vcs_type: 'github'}), headers)
        expect(!user_to_suspend.suspended)
        expect(another_user_to_suspend.suspended)
      end
    end

    context 'org token with wrong scope is used' do
      before {token_perms.update!(permission: 'activity')}
      it 'doesn\'t suspend the users' do
        post("/v3/org/#{organization_id}/suspend", JSON.generate({user_ids: [user_to_suspend.id, another_user_to_suspend.id]}), headers)
        expect(last_response.status).to eq(403)
        post("/v3/org/#{organization_id}/unsuspend", JSON.generate({user_ids: [user_to_suspend.id]}), headers)
        expect(last_response.status).to eq(403)
      end
    end
  end
end
