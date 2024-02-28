require 'travis/testing/payloads'
require 'travis/api/v3/github'

describe 'Hooks', set_app: true do
  before(:each) do
    user.permissions.create repository: repo, admin: true
  end

  let(:authorization) { { 'permissions' => ['repository_settings_create', 'repository_settings_update', 'repository_state_update', 'repository_settings_delete', 'repository_settings_read' ,'repository_cache_view'] } }
  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }
  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }
  before { stub_request(:get, %r((.+)/permissions/repo/)).to_return(status: 404, body: JSON.generate(authorization)) }

  let(:user)    { User.where(login: 'svenfuchs').first }
  let(:repo)    { Repository.first }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

  it 'GET /hooks' do
    response = get '/hooks', {}, headers
    expect(response).to deliver_json_for(user.service_hooks, version: 'v2', type: 'hooks')
  end

  describe 'PUT /hooks' do # TODO really should be /hooks/1
    let(:hook)     { user.service_hooks.first }

    let :payload do
      {
        :name   => 'web',
        :events => Travis::API::V3::GitHub::EVENTS,
        :active => true,
        :config => { url: 'notify.travis-ci.org' }
      }
    end

    before(:each) do
      Travis.config.service_hook_url = 'notify.travis-ci.org'
      allow_any_instance_of(Travis::RemoteVCS::Repository).to receive(:set_hook)
    end

    it 'sets the hook' do
      response = put 'hooks', { hook: { id: hook.id, active: 'true' } }, headers
      expect(repo.reload.active?).to eq(true)
      expect(response).to be_successful
    end

    context 'when the repo is migrating' do
      before { repo.update(migration_status: "migrating") }
      before { put 'hooks', { hook: { id: hook.id, active: 'true' } }, headers }
      it { expect(last_response.status).to eq(403) }
    end

    context 'when the repo is migrated' do
      before { repo.update(migration_status: "migrated") }
      before { put 'hooks', { hook: { id: hook.id, active: 'true' } }, headers }
      it { expect(last_response.status).to eq(403) }
    end
  end
end
