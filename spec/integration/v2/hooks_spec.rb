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
    response.should deliver_json_for(user.service_hooks, version: 'v2', type: 'hooks')
  end

  describe 'PUT /hooks' do # TODO really should be /hooks/1
    let(:hook)     { user.service_hooks.first }
    let(:target)   { "repos/#{hook.owner_name}/#{hook.name}/hooks" }

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
      stub_request(:get, "https://api.github.com/repos/#{repo.slug}/hooks?per_page=100").to_return(status: 200, body: '[]')
      stub_request(:post, "https://api.github.com/repos/#{repo.slug}/hooks")
    end

    it 'sets the hook' do
      response = put 'hooks', { hook: { id: hook.id, active: 'true' } }, headers
      repo.reload.active?.should == true
      response.should be_successful
    end
  end
end
