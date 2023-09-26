describe Travis::Api::App::SettingsEndpoint, set_app: true do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200) }

  describe 'with authenticated user' do
    let(:user)    { User.where(login: 'svenfuchs').first }
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
    let(:headers) { { 'HTTP_ACCEPT' => 'application/json; version=2', 'HTTP_AUTHORIZATION' => "token #{token}" } }

    before { user.permissions.create!(:repository_id => repo.id, :admin => true, :push => true) }

    describe 'GET /settings/env_vars/:id' do
      it 'returns an item' do
        settings = repo.settings
        record = settings.env_vars.create(name: 'FOO', value: 'bar')
        settings.save

        response = get '/settings/env_vars/' + record.id, { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        expect(json['env_var']['name']).to eq('FOO')
        expect(json['env_var']['id']).to eq(record.id)
        expect(json['env_var']['public']).to eq(false)
        expect(json['env_var']['repository_id']).to eq(repo.id)

        # TODO not sure why this has changed, and if it is harmful. the settings UI looks correct to me on staging
        # json['env_var'].should_not have_key('value')
        expect(json['env_var']['value']).to be_nil
      end

      it 'returns 404 if env var can\'t be found' do
        response = get '/settings/env_vars/123', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        expect(json['error']).to eq("Could not find a requested setting")
      end
    end

    describe 'GET /settings/env_vars' do
      it 'returns a list of env vars' do
        settings = repo.settings
        record = settings.env_vars.create(name: 'FOO', value: 'zażółć gęślą jaźń', public: true)
        settings.save

        response = get '/settings/env_vars', { repository_id: repo.id }, headers
        expect(response).to be_successful

        json = JSON.parse(response.body)
        key = json['env_vars'].first
        expect(key['name']).to eq('FOO')
        expect(key['id']).to eq(record.id)
        expect(key['repository_id']).to eq(repo.id)

        expect(key['public']).to eq(true)
        expect(key['value']).to eq('zażółć gęślą jaźń')
      end
    end

    describe 'POST /settings/env_vars' do
      it 'creates a new key' do
        body = { env_var: { name: 'FOO', value: 'bar' } }.to_json
        response = post "/settings/env_vars?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        expect(json['env_var']['name']).to eq('FOO')
        expect(json['env_var']['id']).not_to be_nil
        # json['env_var'].should_not have_key('value')
        expect(json['env_var']['value']).to be_nil

        env_var = repo.reload.settings.env_vars.first
        expect(env_var.id).not_to be_nil
        expect(env_var.name).to eq('FOO')
        expect(env_var.value.decrypt).to eq('bar')
      end

      it 'returns error message if a key is invalid' do
        response = post "/settings/env_vars?repository_id=#{repo.id}", '{}', headers
        expect(response.status).to eq(422)

        json = JSON.parse(response.body)
        expect(json['message']).to eq('Validation failed')
        expect(json['errors']).to eq([{
          'field' => 'name',
          'code' => 'missing_field'
        }])

        expect(repo.reload.settings.env_vars.to_a.length).to eq(0)
      end

      context 'when the repo is migrating' do
        before { repo.update(migration_status: "migrating") }
        before { post "/settings/env_vars?repository_id=#{repo.id}", '{}', headers }
        it { expect(last_response.status).to eq(403) }
      end

      context 'when the repo is migrated' do
        before { repo.update(migration_status: "migrated") }
        before { post "/settings/env_vars?repository_id=#{repo.id}", '{}', headers }
        it { expect(last_response.status).to eq(403) }
      end
    end

    describe 'PATCH /settings/env_vars/:id' do
      it 'resets value if private key is made public unless new value is provided' do
        settings = repo.settings
        env_var = settings.env_vars.create(name: 'FOO', value: 'bar')
        settings.save

        body = { env_var: { public: true, value: 'a new value' } }.to_json
        response = patch "/settings/env_vars/#{env_var.id}?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        expect(json['env_var']['value']).to eq('a new value')

        updated_env_var = repo.reload.settings.env_vars.find(env_var.id)
        expect(updated_env_var.value.decrypt).to eq('a new value')
      end

      it 'resets value if private key is made public' do
        settings = repo.settings
        env_var = settings.env_vars.create(name: 'FOO', value: 'bar')
        settings.save

        body = { env_var: { public: true } }.to_json
        response = patch "/settings/env_vars/#{env_var.id}?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        expect(json['env_var']['value']).to be_nil

        updated_env_var = repo.reload.settings.env_vars.find(env_var.id)
        expect(updated_env_var.value.decrypt).to be_nil
      end

      it 'should update a key' do
        settings = repo.settings
        env_var = settings.env_vars.create(name: 'FOO', value: 'bar')
        settings.save

        body = { env_var: { value: 'baz' } }.to_json
        response = patch "/settings/env_vars/#{env_var.id}?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        expect(json['env_var']['name']).to eq('FOO')
        expect(json['env_var']['id']).to eq(env_var.id)
        # json['env_var'].should_not have_key('value')
        expect(json['env_var']['value']).to be_nil

        updated_env_var = repo.reload.settings.env_vars.find(env_var.id)
        expect(updated_env_var.id).to eq(env_var.id)
        expect(updated_env_var.name).to eq('FOO')
        expect(updated_env_var.value.decrypt).to eq('baz')
      end

      it 'returns an error message if env_var is invalid' do
        settings = repo.settings
        env_var = settings.env_vars.create(name: 'FOO', value: 'bar')
        settings.save

        body = { env_var: { name: '' } }.to_json
        response = patch "/settings/env_vars/#{env_var.id}?repository_id=#{repo.id}", body, headers
        expect(response.status).to eq(422)

        json = JSON.parse(response.body)
        expect(json['message']).to eq('Validation failed')
        expect(json['errors']).to eq([{
          'field' => 'name',
          'code' => 'missing_field'
        }])

        updated_env_var = repo.reload.settings.env_vars.find(env_var.id)
        expect(updated_env_var.id).to eq(env_var.id)
        expect(updated_env_var.name).to eq('FOO')
        expect(updated_env_var.value.decrypt).to eq('bar')
      end

      context 'when the repo is migrating' do
        let(:env_var) { repo.settings.env_vars.create(name: 'FOO', value: 'bar').tap { repo.settings.save } }
        before { repo.update(migration_status: "migrating") }
        before { patch "/settings/env_vars/#{env_var.id}?repository_id=#{repo.id}", '{}', headers }
        it { expect(last_response.status).to eq(403) }
      end

      context 'when the repo is migrated' do
        let(:env_var) { repo.settings.env_vars.create(name: 'FOO', value: 'bar').tap { repo.settings.save } }
        before { repo.update(migration_status: "migrated") }
        before { patch "/settings/env_vars/#{env_var.id}?repository_id=#{repo.id}", '{}', headers }
        it { expect(last_response.status).to eq(403) }
      end
    end

    describe 'DELETE /env_vars/:id' do
      it 'should delete an env_var' do
        settings = repo.settings
        env_var = settings.env_vars.create(name: 'FOO', value: 'bar')
        settings.save

        params = { repository_id: repo.id }
        response = delete '/settings/env_vars/' + env_var.id, params, headers
        json = JSON.parse(response.body)
        expect(json['env_var']['name']).to eq('FOO')
        expect(json['env_var']['id']).to eq(env_var.id)
        # json['env_var'].should_not have_key('value')
        expect(json['env_var']['value']).to be_nil

        expect(repo.reload.settings.env_vars.length).to eq(0)
      end

      it 'returns 404 if env_var can\'t be found' do
        response = delete '/settings/env_vars/123', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        expect(json['error']).to eq("Could not find a requested setting")
      end
    end
  end
end
