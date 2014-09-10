require 'spec_helper'

describe Travis::Api::App::SettingsEndpoint do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

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
        json['env_var']['name'].should == 'FOO'
        json['env_var']['id'].should == record.id
        json['env_var']['public'].should be_false
        json['env_var']['repository_id'].should == repo.id
        json['env_var'].should_not have_key('value')
      end

      it 'returns 404 if env var can\'t be found' do
        response = get '/settings/env_vars/123', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        json['error'].should == "Could not find a requested setting"
      end
    end

    describe 'GET /settings/env_vars' do
      it 'returns a list of env vars' do
        settings = repo.settings
        record = settings.env_vars.create(name: 'FOO', value: 'bar')
        settings.save

        response = get '/settings/env_vars', { repository_id: repo.id }, headers
        response.should be_successful

        json = JSON.parse(response.body)
        key = json['env_vars'].first
        key['name'].should == 'FOO'
        key['id'].should == record.id
        key['repository_id'].should == repo.id
        key['public'].should be_false
        key.should_not have_key('value')
      end
    end

    describe 'POST /settings/env_vars' do
      it 'creates a new key' do
        body = { env_var: { name: 'FOO', value: 'bar' } }.to_json
        response = post "/settings/env_vars?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        json['env_var']['name'].should == 'FOO'
        json['env_var']['id'].should_not be_nil
        json['env_var'].should_not have_key('value')

        env_var = repo.reload.settings.env_vars.first
        env_var.id.should_not be_nil
        env_var.name.should == 'FOO'
        env_var.value.decrypt.should == 'bar'
      end

      it 'returns error message if a key is invalid' do
        response = post "/settings/env_vars?repository_id=#{repo.id}", '{}', headers
        response.status.should == 422

        json = JSON.parse(response.body)
        json['message'].should == 'Validation failed'
        json['errors'].should == [{
          'field' => 'name',
          'code' => 'missing_field'
        }]

        repo.reload.settings.env_vars.to_a.length.should == 0
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
        json['env_var']['value'].should == 'a new value'

        updated_env_var = repo.reload.settings.env_vars.find(env_var.id)
        updated_env_var.value.decrypt.should == 'a new value'
      end

      it 'resets value if private key is made public' do
        settings = repo.settings
        env_var = settings.env_vars.create(name: 'FOO', value: 'bar')
        settings.save

        body = { env_var: { public: true } }.to_json
        response = patch "/settings/env_vars/#{env_var.id}?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        json['env_var']['value'].should be_nil

        updated_env_var = repo.reload.settings.env_vars.find(env_var.id)
        updated_env_var.value.decrypt.should be_nil
      end

      it 'should update a key' do
        settings = repo.settings
        env_var = settings.env_vars.create(name: 'FOO', value: 'bar')
        settings.save

        body = { env_var: { value: 'baz' } }.to_json
        response = patch "/settings/env_vars/#{env_var.id}?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        json['env_var']['name'].should == 'FOO'
        json['env_var']['id'].should == env_var.id
        json['env_var'].should_not have_key('value')

        updated_env_var = repo.reload.settings.env_vars.find(env_var.id)
        updated_env_var.id.should == env_var.id
        updated_env_var.name.should == 'FOO'
        updated_env_var.value.decrypt.should == 'baz'
      end

      it 'returns an error message if env_var is invalid' do
        settings = repo.settings
        env_var = settings.env_vars.create(name: 'FOO', value: 'bar')
        settings.save

        body = { env_var: { name: '' } }.to_json
        response = patch "/settings/env_vars/#{env_var.id}?repository_id=#{repo.id}", body, headers
        response.status.should == 422

        json = JSON.parse(response.body)
        json['message'].should == 'Validation failed'
        json['errors'].should == [{
          'field' => 'name',
          'code' => 'missing_field'
        }]

        updated_env_var = repo.reload.settings.env_vars.find(env_var.id)
        updated_env_var.id.should == env_var.id
        updated_env_var.name.should == 'FOO'
        updated_env_var.value.decrypt.should == 'bar'
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
        json['env_var']['name'].should == 'FOO'
        json['env_var']['id'].should == env_var.id
        json['env_var'].should_not have_key('value')

        repo.reload.settings.env_vars.should have(0).env_vars
      end

      it 'returns 404 if env_var can\'t be found' do
        response = delete '/settings/env_vars/123', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        json['error'].should == "Could not find a requested setting"
      end
    end
  end
end
