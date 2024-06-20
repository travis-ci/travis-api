describe 'ssh keys endpoint', set_app: true do
  let(:repo)    { FactoryBot.create(:repository) }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 401) }

  describe 'without an authenticated user' do
    let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }
    let(:user)    { FactoryBot.create(:user) }

    describe 'GET /ssh_key' do
      it 'responds with 401' do
        response = get "/settings/ssh_key/#{repo.id}", {}, headers
        expect(response).not_to be_successful
        expect(response.status).to eq(401)
      end
    end

    describe 'PATCH /ssh_key' do
      it 'responds with 401' do
        response = patch "/settings/ssh_key/#{repo.id}", {}, headers
        expect(response).not_to be_successful
        expect(response.status).to eq(401)
      end
    end

    describe 'DELETE /ssh_key' do
      it 'responds with 401' do
        response = delete "/settings/ssh_key/#{repo.id}", {}, headers
        expect(response).not_to be_successful
        expect(response.status).to eq(401)
      end
    end
  end

  describe 'with authenticated user' do
    let(:user)    { FactoryBot.create(:user) }
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
        expect(json['ssh_key']['description']).to eq('key for my repo')
        expect(json['ssh_key']['id']).to eq(repo.id)
        expect(json['ssh_key']).not_to have_key('value')
        expect(json['ssh_key']['fingerprint']).to eq('57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40')
      end

      it 'returns 404 if ssh_key can\'t be found' do
        response = get "/settings/ssh_key/#{repo.id}", {}, headers
        json = JSON.parse(response.body)
        expect(json['error']).to eq("Could not find a requested setting")
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
        expect(json['ssh_key']['description']).to eq('bar')
        expect(json['ssh_key']).not_to have_key('value')

        updated_ssh_key = repo.reload.settings.ssh_key
        expect(updated_ssh_key.description).to eq('bar')
        expect(updated_ssh_key.repository_id).to eq(repo.id)
        expect(updated_ssh_key.value.decrypt).to eq(new_key)
      end

      it 'should update a eddsa key' do
        settings = repo.settings
        ssh_key = settings.create(:ssh_key, description: 'foo', value: TEST_PRIVATE_KEY)
        settings.save

        new_key = "-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBQXfKTsmUKEONVc2i974UqTzI+Jci36WMfk/BnsWbU1gAAAJgPwlTaD8JU
2gAAAAtzc2gtZWQyNTUxOQAAACBQXfKTsmUKEONVc2i974UqTzI+Jci36WMfk/BnsWbU1g
AAAEBKnjD7h7IMc9yK5y+8yddm7Lze3vvP7+4OIbsYJ83raFBd8pOyZQoQ41VzaL3vhSpP
Mj4lyLfpYx+T8GexZtTWAAAAEmJnQExBUFRPUC1ISTQ5Q0hOTgECAw==
-----END OPENSSH PRIVATE KEY-----"

        body = { ssh_key: { description: 'bar', value: new_key } }.to_json
        response = patch "/settings/ssh_key/#{repo.id}", body, headers
        json = JSON.parse(response.body)
        expect(json['ssh_key']['description']).to eq('bar')
        expect(json['ssh_key']).not_to have_key('value')

        updated_ssh_key = repo.reload.settings.ssh_key
        expect(updated_ssh_key.description).to eq('bar')
        expect(updated_ssh_key.repository_id).to eq(repo.id)
        expect(updated_ssh_key.value.decrypt).to eq(new_key)
      end


      it 'returns an error message if ssh_key is invalid' do
        settings = repo.settings
        ssh_key = settings.create(:ssh_key, description: 'foo', value: 'the key')
        settings.save

        body = { ssh_key: { value: nil } }.to_json
        response = patch "/settings/ssh_key/#{repo.id}", body, headers

        expect(response.status).to eq(422)

        json = JSON.parse(response.body)
        expect(json['message']).to eq('Validation failed')
        expect(json['errors']).to eq([{
          'field' => 'value',
          'code' => 'missing_field'
        }])

        ssh_key = repo.reload.settings.ssh_key
        expect(ssh_key.description).to eq('foo')
        expect(ssh_key.repository_id).to eq(repo.id)
        expect(ssh_key.value.decrypt).to eq('the key')
      end

      context 'when the repo is migrating' do
        let(:env_var) { repo.settings.create(:ssh_key, description: 'foo', value: TEST_PRIVATE_KEY).tap { repo.settings.save } }
        before { repo.update(migration_status: "migrating") }
        before { patch "/settings/ssh_key/#{repo.id}", '{"settings": {}}', headers }
        it { expect(last_response.status).to eq(403) }
      end

      context 'when the repo is migrated' do
        let(:env_var) { repo.settings.create(:ssh_key, description: 'foo', value: TEST_PRIVATE_KEY).tap { repo.settings.save } }
        before { repo.update(migration_status: "migrated") }
        before { patch "/settings/ssh_key/#{repo.id}", '{}', headers }
        it { expect(JSON.parse(last_response.body)["error_type"]).to eq("migrated_repository") }
        it { expect(last_response.status).to eq(403) }
      end
    end

    describe 'DELETE /ssh_keys/:id' do
      it 'should nullify an ssh_key' do
        settings = repo.settings
        ssh_key = settings.create(:ssh_key, description: 'foo', value: 'the key')
        settings.save

        response = delete "/settings/ssh_key/#{repo.id}", {}, headers
        json = JSON.parse(response.body)
        expect(json['ssh_key']['description']).to eq('foo')
        expect(json['ssh_key']).not_to have_key('value')

        expect(repo.reload.settings.ssh_key).to be_nil
      end
    end
  end
end
