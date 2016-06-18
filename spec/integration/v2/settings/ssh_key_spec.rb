describe 'ssh keys endpoint', set_app: true do
  let(:repo)    { Factory(:repository) }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  describe 'without an authenticated user' do
    let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }
    let(:user)    { Factory(:user) }

    describe 'GET /ssh_key' do
      it 'responds with 401' do
        response = get "/settings/ssh_key/#{repo.id}", {}, headers
        response.should_not be_successful
        response.status.should == 401
      end
    end

    describe 'PATCH /ssh_key' do
      it 'responds with 401' do
        response = patch "/settings/ssh_key/#{repo.id}", {}, headers
        response.should_not be_successful
        response.status.should == 401
      end
    end

    describe 'DELETE /ssh_key' do
      it 'responds with 401' do
        response = delete "/settings/ssh_key/#{repo.id}", {}, headers
        response.should_not be_successful
        response.status.should == 401
      end
    end
  end

  describe 'with authenticated user' do
    let(:user)    { Factory(:user) }
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
    let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

    before { user.permissions.create!(:repository_id => repo.id, :admin => true, :push => true) }

    describe 'GET /ssh_key' do
      it 'returns an item' do
        settings = repo.settings
        record = settings.create(:ssh_key, description: 'key for my repo', value: TEST_PRIVATE_KEY)
        settings.save

        response = get "/settings/ssh_key/#{repo.id}", {}, headers
        json = JSON.parse(response.body)
        json['ssh_key']['description'].should == 'key for my repo'
        json['ssh_key']['id'].should == repo.id
        json['ssh_key'].should_not have_key('value')
        json['ssh_key']['fingerprint'].should == '57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40'
      end

      it 'returns 404 if ssh_key can\'t be found' do
        response = get "/settings/ssh_key/#{repo.id}", {}, headers
        json = JSON.parse(response.body)
        json['error'].should == "Could not find a requested setting"
      end
    end

    describe 'PATCH /settings/ssh_key' do
      it 'should update a key' do
        settings = repo.settings
        ssh_key = settings.create(:ssh_key, description: 'foo', value: TEST_PRIVATE_KEY)
        settings.save

        new_key = OpenSSL::PKey::RSA.generate(2048).to_s
        body = { ssh_key: { description: 'bar', value: new_key } }.to_json
        response = patch "/settings/ssh_key/#{repo.id}", body, headers
        json = JSON.parse(response.body)
        json['ssh_key']['description'].should == 'bar'
        json['ssh_key'].should_not have_key('value')

        updated_ssh_key = repo.reload.settings.ssh_key
        updated_ssh_key.description.should == 'bar'
        updated_ssh_key.repository_id.should == repo.id
        updated_ssh_key.value.decrypt.should == new_key
      end

      it 'returns an error message if ssh_key is invalid' do
        settings = repo.settings
        ssh_key = settings.create(:ssh_key, description: 'foo', value: 'the key')
        settings.save

        body = { ssh_key: { value: nil } }.to_json
        response = patch "/settings/ssh_key/#{repo.id}", body, headers

        response.status.should == 422

        json = JSON.parse(response.body)
        json['message'].should == 'Validation failed'
        json['errors'].should == [{
          'field' => 'value',
          'code' => 'missing_field'
        }]

        ssh_key = repo.reload.settings.ssh_key
        ssh_key.description.should == 'foo'
        ssh_key.repository_id.should == repo.id
        ssh_key.value.decrypt.should == 'the key'
      end
    end

    describe 'DELETE /ssh_keys/:id' do
      it 'should nullify an ssh_key' do
        settings = repo.settings
        ssh_key = settings.create(:ssh_key, description: 'foo', value: 'the key')
        settings.save

        response = delete "/settings/ssh_key/#{repo.id}", {}, headers
        json = JSON.parse(response.body)
        json['ssh_key']['description'].should == 'foo'
        json['ssh_key'].should_not have_key('value')

        repo.reload.settings.ssh_key.should be_nil
      end
    end
  end
end
