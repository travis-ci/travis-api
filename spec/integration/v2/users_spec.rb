describe 'Users', set_app: true do
  let(:user)    { User.first }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

  before { allow_any_instance_of(Travis::RemoteVCS::User).to receive(:check_scopes) }

  let(:authorization) { { 'permissions' => ['repository_settings_create', 'repository_settings_update', 'repository_state_update', 'repository_settings_delete'] } }
  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  context 'GET /users/:id' do
    let(:repo1) { FactoryBot.create(:repository, owner: user) }
    let(:org) { FactoryBot.create(:org) }
    let(:repo2) { FactoryBot.create(:repository, owner: org) }

    before do
      user.permissions.create!(repository: repo1)
      user.permissions.create!(repository: repo2)
      allow_any_instance_of(Travis::RemoteVCS::User).to receive(:check_scopes)
    end

    it 'fetches a list of channels for a user' do
      response = get "/users/#{user.id}", {}, headers
      expect(JSON.parse(response.body)['user']['channels']).to eq(["private-user-#{user.id}"])
    end
  end

  context 'PUT /users/:id' do
    it 'updates user data and returns the user' do
      params = {user: {id: user.id, locale: 'pl'}}
      response = put "/users/#{user.id}", params, headers
      expect(response).to be_successful
#      expect(response).to deliver_json_for('result' => true, 'flash' => [{ 'notice' => 'Your profile was successfully updated.' }])
      expect(user.reload.locale).to eq('pl')
    end
  end

  context 'POST /users/sync' do
    it 'syncs current_user repos' do
      user.update_attribute :is_syncing, false
      response = post "/users/sync", {}, headers
      expect(response).to be_successful
    end
  end
end
