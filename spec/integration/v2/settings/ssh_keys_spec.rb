require 'spec_helper'

describe Travis::Api::App::SettingsEndpoint do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  describe 'with authenticated user' do
    let(:user)    { User.where(login: 'svenfuchs').first }
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
    let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

    before { user.permissions.create!(:repository_id => repo.id, :admin => true, :push => true) }

    describe 'GET /ssh_keys/:id' do
      it 'returns an item' do
        settings = repo.settings
        record = settings.ssh_keys.create(name: 'key for my repo', content: 'the key')
        settings.save

        response = get '/settings/ssh_keys/' + record.id, { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        json['ssh_key']['name'].should == 'key for my repo'
        json['ssh_key']['id'].should == record.id
        json['ssh_key'].should_not have_key('content')
      end

      it 'returns 404 if ssh_key can\'t be found' do
        response = get '/settings/ssh_keys/123', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        json['error'].should == "Could not find a requested setting"
      end
    end

    describe 'GET /settings/ssh_keys' do
      it 'returns a list of ssh_keys' do
        settings = repo.settings
        record = settings.ssh_keys.create(name: 'key for my repo', content: 'the key')
        settings.save

        response = get '/settings/ssh_keys', { repository_id: repo.id }, headers
        response.should be_successful

        json = JSON.parse(response.body)
        key = json['ssh_keys'].first
        key['name'].should == 'key for my repo'
        key['id'].should == record.id
        key.should_not have_key('content')
      end
    end

    describe 'POST /settings/ssh_keys' do
      it 'creates a new key' do
        body = { ssh_key: { name: 'foo', content: 'content' } }.to_json
        response = post "/settings/ssh_keys?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        json['ssh_key']['name'].should == 'foo'
        json['ssh_key']['id'].should_not be_nil
        json['ssh_key'].should_not have_key('content')

        ssh_key = repo.reload.settings.ssh_keys.first
        ssh_key.id.should_not be_nil
        ssh_key.name.should == 'foo'
        ssh_key.content.decrypt.should == 'content'
      end

      it 'returns error message if a key is invalid' do
        response = post "/settings/ssh_keys?repository_id=#{repo.id}", '{}', headers
        response.status.should == 422

        json = JSON.parse(response.body)
        json['message'].should == 'Validation failed'
        json['errors'].should == [{
          'field' => 'name',
          'code' => 'missing_field'
        }]

        repo.reload.settings.ssh_keys.length.should == 0
      end
    end

    describe 'PATCH /settings/ssh_keys/:id' do
      it 'should update a key' do
        settings = repo.settings
        ssh_key = settings.ssh_keys.create(name: 'foo', content: 'content')
        settings.save

        body = { ssh_key: { name: 'bar', content: 'a new content' } }.to_json
        response = patch "/settings/ssh_keys/#{ssh_key.id}?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        json['ssh_key']['name'].should == 'bar'
        json['ssh_key']['id'].should == ssh_key.id
        json['ssh_key'].should_not have_key('content')

        updated_ssh_key = repo.reload.settings.ssh_keys.find(ssh_key.id)
        updated_ssh_key.id.should == ssh_key.id
        updated_ssh_key.name.should == 'bar'
        updated_ssh_key.content.decrypt.should == 'a new content'
      end

      it 'returns an error message if ssh_key is invalid' do
        settings = repo.settings
        ssh_key = settings.ssh_keys.create(name: 'foo', content: 'content')
        settings.save

        body = { ssh_key: { name: '' } }.to_json
        response = patch "/settings/ssh_keys/#{ssh_key.id}?repository_id=#{repo.id}", body, headers
        response.status.should == 422

        json = JSON.parse(response.body)
        json['message'].should == 'Validation failed'
        json['errors'].should == [{
          'field' => 'name',
          'code' => 'missing_field'
        }]

        updated_ssh_key = repo.reload.settings.ssh_keys.find(ssh_key.id)
        updated_ssh_key.id.should == ssh_key.id
        updated_ssh_key.name.should == 'foo'
        updated_ssh_key.content.decrypt.should == 'content'
      end
    end

    describe 'DELETE /ssh_keys/:id' do
      it 'should delete an ssh_key' do
        settings = repo.settings
        ssh_key = settings.ssh_keys.create(name: 'foo', content: 'content')
        settings.save

        params = { repository_id: repo.id }
        response = delete '/settings/ssh_keys/' + ssh_key.id, params, headers
        json = JSON.parse(response.body)
        json['ssh_key']['name'].should == 'foo'
        json['ssh_key']['id'].should == ssh_key.id
        json['ssh_key'].should_not have_key('content')

        repo.reload.settings.ssh_keys.should have(0).ssh_keys
      end

      it 'returns 404 if ssh_key can\'t be found' do
        response = delete '/settings/ssh_keys/123', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        json['error'].should == "Could not find a requested setting"
      end
    end
  end
end
