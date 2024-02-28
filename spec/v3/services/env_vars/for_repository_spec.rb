require 'spec_helper'

describe Travis::API::V3::Services::EnvVars::ForRepository, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:env_var) { { id: 'abc', name: 'FOO', value: Travis::Settings::EncryptedValue.new('bar'), public: true, branch: 'foo', repository_id: repo.id } }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe 'not authenticated' do
    before { get("/v3/repo/#{repo.id}/env_vars") }
    include_examples 'not authenticated'
  end

  describe 'authenticated, missing repo' do
    before { get("/v3/repo/999999999/env_vars", {}, auth_headers) }
    include_examples 'missing repo'
  end

  describe 'authenticated, existing repo, no env vars' do
    before do
      get("/v3/repo/#{repo.id}/env_vars", {}, auth_headers)
    end
    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'env_vars',
        '@href' => "/v3/repo/#{repo.id}/env_vars",
        '@representation' => 'standard',
        'env_vars' => []
      )
    end
  end

  describe 'authenticated, existing repo, existing env vars' do
    let(:authorization) { { 'permissions' => ['repository_log_view', 'repository_settings_read'] } }
    before do
      repo.update(settings: { env_vars: [env_var] })
      get("/v3/repo/#{repo.id}/env_vars", {}, auth_headers)
    end
    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'env_vars',
        '@href' => "/v3/repo/#{repo.id}/env_vars",
        '@representation' => 'standard',
        'env_vars' => [
          {
            '@type' => 'env_var',
            '@href' => "/v3/repo/#{repo.id}/env_var/#{env_var[:id]}",
            '@representation' => 'standard',
            '@permissions' => { 'read' => true, 'write' => false },
            'id' => env_var[:id],
            'name' => env_var[:name],
            'value' => env_var[:value].decrypt,
            'public' => env_var[:public],
            'branch' => env_var[:branch]
          }
        ]
      )
    end
  end
end
