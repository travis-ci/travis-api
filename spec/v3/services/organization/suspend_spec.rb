describe Travis::API::V3::Services::Organization::Suspend, set_app: true do
  let(:organization_id) { 1 }
  let(:organization) { FactoryBot.create(:org) }

  context 'unauthenticated' do
    it 'responds 403' do
      post("/v3/org/#{organization_id}/suspend",JSON.generate({user_ids: [1,2,3]}))
      expect(last_response.status).to eq(403)
    end
  end

  describe 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:user_to_suspend) { FactoryBot.create(:user) }
    let(:another_user_to_suspend) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    context 'user is admin' do
      before do
        organization.memberships.create(user: user, role: 'admin')
        organization.memberships.create(user: user_to_suspend, role: 'member')
        organization.memberships.create(user: another_user_to_suspend, role: 'member')
      end

      it 'suspends the users' do
        post("/v3/org/#{organization_id}/suspend", JSON.generate({user_ids: [user_to_suspend.id, another_user_to_suspend.id]}), headers)
        expect(last_response.status).to eq(200)
        expect(user_to_suspend.suspended)
        expect(another_user_to_suspend.suspended)
        post("/v3/org/#{organization_id}/unsuspend", JSON.generate({user_ids: [user_to_suspend.id]}), headers)
        expect(!user_to_suspend.suspended)
        expect(another_user_to_suspend.suspended)
      end
    end
  end
end
