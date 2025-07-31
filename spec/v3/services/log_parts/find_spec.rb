require 'spec_helper'

describe Travis::API::V3::Services::LogParts, set_app: true do
  let(:user)        { FactoryBot.create(:user) }
  let(:repo)        { FactoryBot.create(:repository, owner_name: user.login, name: 'minimal', owner: user)}
  let(:build)       { FactoryBot.create(:build, repository: repo) }
  let(:perm)        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, push: true)}
  let(:job)         { Travis::API::V3::Models::Job.create(build: build, started_at: Time.now - 10.days, repository: repo) }
  let(:token)       { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers)     { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:parsed_body) { JSON.load(body) }
  let(:time)        { Time.now }
  let :log_parts do
      [
        {
          'content' => 'a\nb\nc\n',
          'final' => false,
          'number' => 0,
        },
        {
          'content' => 'x',
          'final' => true,
          'number' => 1,
        }
      ]
  end

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }
  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }
  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  before do
    allow_any_instance_of(Travis::API::V3::AccessControl::LegacyToken).to receive(:visible?).and_return(true)
    remote = double('remote')
    allow(Travis::RemoteLog::Remote).to receive(:new).and_return(remote)
    allow(remote).to receive(:find_parts_by_job_id).and_return(log_parts.map { |part| Travis::RemoteLogPart.new(part)})
  end

  describe 'returns log with an array of Log Parts' do
    let(:authorization) {
      { 'permissions' => ['repository_log_view'] }
    }
    let(:headers) {{}}
    example do

      get("/v3/job/#{job.id}/log_parts", {}, headers)

      expect(parsed_body).to match(
        '@type' => 'log_parts',
        '@representation' => 'standard',
        'log_parts' => log_parts
      )
    end
  end
  describe 'returns log with an array of Log Parts' do
    let :log_parts do
      [{'content': nil, 'number': 0},{'final': nil, 'number': 1}]
    end

    let(:authorization) {
      { 'permissions' => ['repository_log_view'] }
    }
    let(:headers) {{}}
    example 'only info' do

      get("/v3/job/#{job.id}/log_parts?content=false", {}, headers)

      expect(parsed_body).to match(
        '@type' => 'log_parts',
        '@representation' => 'standard',
        'log_parts' => [{'number' => 0},{'number' => 1}]
      )
    end
  end
end
