require 'travis/testing/payloads'
require 'travis/api/v3/github'

describe 'Hooks', set_app: true do
  before(:each) do
    user.permissions.create repository: repo, admin: true
  end

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
      stub_request(:get, "https://api.github.com/repositories/#{repo.github_id}/hooks?per_page=100").to_return(status: 200, body: '[]')
      stub_request(:post, "https://api.github.com/repositories/#{repo.github_id}/hooks")
    end

    it 'sets the hook' do
      response = put 'hooks', { hook: { id: hook.id, active: 'true' } }, headers
      expect(repo.reload.active?).to eq(true)
      expect(response).to be_successful
    end

    context 'when the repo is migrating' do
      before { repo.update_attributes(migration_status: "migrating") }
      before { put 'hooks', { hook: { id: hook.id, active: 'true' } }, headers }
      it { expect(last_response.status).to eq(403) }
    end

    context 'when the repo is migrated' do
      before { repo.update_attributes(migration_status: "migrated") }
      before { put 'hooks', { hook: { id: hook.id, active: 'true' } }, headers }
      it { expect(last_response.status).to eq(403) }
    end
  end
end
