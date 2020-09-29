describe Travis::API::V3::Services::BuildPermissions::UpdateForRepo, set_app: true do
  let(:organization) { FactoryBot.create(:org) }
  let(:repository) { FactoryBot.create(:repository, owner: organization) }
  let(:user) { FactoryBot.create(:user, login: 'pavel-d') }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) { { 'HTTP_AUTHORIZATION'  =>  "token #{token}" } }

  context 'not authenticated' do
    it 'returns access error' do
      patch("/v3/repo/#{repository.id}/build_permissions", { user_ids: [user.id], permission: false })
      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    context 'user is admin' do
      before do
        organization.memberships.create(user: user, role: 'admin')
        FactoryBot.create(:permission, user: user, repository: repository, admin: true, build: true)
      end

      it 'updates build permissions' do
        patch("/v3/repo/#{repository.id}/build_permissions", { user_ids: [user.id], permission: false }, headers)
        expect(last_response.status).to eq(204)
        expect(repository.permissions.first.build).to eq(false)
      end
    end

    context 'user is a member' do
      before do
        organization.memberships.create(user: user, role: 'member')
        FactoryBot.create(:permission, user: user, repository: repository, build: true)
      end

      it 'returns access error' do
        patch("/v3/repo/#{repository.id}/build_permissions", { user_ids: [user.id], permission: false }, headers)
        expect(last_response.status).to eq(403)
      end
    end
  end
end
