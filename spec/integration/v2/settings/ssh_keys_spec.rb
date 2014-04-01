require 'spec_helper'

describe Travis::Api::App::SettingsEndpoint do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  describe 'with authenticated user' do
    let(:user)    { User.where(login: 'svenfuchs').first }
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
    let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

    before { user.permissions.create!(:repository_id => repo.id, :admin => true, :push => true) }

    describe 'GET /items/:id' do
      it 'returns an item' do
        settings = repo.settings
        record = settings.ssh_keys.create(name: 'key for my repo', content: 'the key')
        settings.save

        response = get '/settings/ssh_keys/' + record.id, { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        json['ssh_key']['name'].should == 'key for my repo'
        json['ssh_key']['id'].should == record.id
        json['ssh_key'].should_not have_key('secret')
      end

      it 'returns 404 if ssh_key can\'t be found' do
        response = get '/settings/ssh_key/123', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        json['error'].should == "Could not find a requested setting"
      end
    end
  end
end
