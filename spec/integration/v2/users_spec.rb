describe 'Users', set_app: true do
  let(:user)    { User.first }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

  context 'GET /users/:id' do
    let(:repo1) { Factory(:repository, owner: user) }
    let(:org) { Factory(:org) }
    let(:repo2) { Factory(:repository, owner: org) }

    before do
      user.permissions.create!(repository: repo1)
      user.permissions.create!(repository: repo2)
      ::Travis::RemoteVCS::User.any_instance.stubs(:check_scopes).returns(true)
    end

    it 'fetches a list of channels for a user' do
      response = get "/users/#{user.id}", {}, headers
      JSON.parse(response.body)['user']['channels'].should == ["private-user-#{user.id}"]
    end
  end

  context 'PUT /users/:id' do
    it 'updates user data and returns the user' do
      params = {user: {id: user.id, locale: 'pl'}}
      response = put "/users/#{user.id}", params, headers
      response.should be_successful
      response.should deliver_json_for('result' => true, 'flash' => [{ 'notice' => 'Your profile was successfully updated.' }])
      user.reload.locale.should == 'pl'
    end
  end

  context 'POST /users/sync' do
    it 'syncs current_user repos' do
      user.update_attribute :is_syncing, false
      response = post "/users/sync", {}, headers
      response.should be_successful
    end
  end
end
