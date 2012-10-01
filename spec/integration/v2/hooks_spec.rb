require 'spec_helper'
require 'travis/testing/payloads'

describe 'Hooks' do
  before(:each) do
    Scenario.default
    user.permissions.create repository: repo, admin: true
  end

  let(:user)    { User.where(login: 'svenfuchs').first }
  let(:repo)    { Repository.first }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

  it 'GET /hooks' do
    response = get '/hooks', {}, headers
    response.should deliver_json_for(user.service_hooks, version: 'v2', type: 'hooks')
  end

  describe 'PUT /hooks' do # TODO really should be /hooks/1
    let(:hook)     { user.service_hooks.first }
    let(:target)   { "repos/#{hook.owner_name}/#{hook.name}/hooks" }

    let :payload do
      {
        :name   => 'travis',
        :events => ServiceHook::EVENTS,
        :active => true,
        :config => { :user => user.login, :token => user.tokens.first.token, :domain => 'listener.travis-ci.org' }
      }
    end

    before(:each) do
      Travis.config.stubs(:service_hook_url).returns('listener.travis-ci.org')
    end

    it 'creates a new hook' do
      GH.stubs(:[]).returns([])
      GH.expects(:post).with(target, payload)
      put 'hooks', { hook: { id: hook.id, active: 'true' } }, headers
      repo.reload.active?.should be_true
    end

    it 'updates an existing hook to be active' do
      GH.stubs(:[]).returns([GH.load(PAYLOADS[:github][:hook_inactive])])
      GH.expects(:post).with(target, payload)
      put 'hooks', { hook: { id: hook.id, active: 'true' } }, headers
      repo.reload.active?.should be_true
    end

    it 'updates an existing repository to be inactive' do
      GH.stubs(:[]).returns([GH.load(PAYLOADS[:github][:hook_active])])
      GH.expects(:post).with(target, payload.merge(:active => false))
      put 'hooks', { hook: { id: hook.id, active: 'false' } }, headers
      repo.reload.active?.should be_false
    end
  end
end
