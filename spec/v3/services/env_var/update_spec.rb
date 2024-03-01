require 'spec_helper'

describe Travis::API::V3::Services::EnvVar::Update, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:env_var) { { id: 'abc', name: 'FOO', value: Travis::Settings::EncryptedValue.new('bar'), public: true, branch: 'foo', repository_id: repo.id } }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe 'not authenticated' do
    before { patch("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}") }
    include_examples 'not authenticated'
  end

  describe 'authenticated, missing repo' do
    before { patch("/v3/repo/999999999/env_var/#{env_var[:id]}", {}, auth_headers) }
    include_examples 'missing repo'
  end

  describe 'authenticated, existing repo, missing env var' do
    before { patch("/v3/repo/#{repo.id}/env_var/foo", {}, auth_headers) }
    include_examples 'missing env_var'
  end

  describe 'authenticated, existing repo, existing env var, incorrect permissions' do
    let(:params) do
      {
        'env_var.name' => 'QUX'
      }
    end

    let(:authorization) { { 'permissions' => ['repository_settings_read'] } }
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
      repo.update(settings: { env_vars: [env_var], foo: 'bar' })
      patch("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}", JSON.generate(params), auth_headers.merge(json_headers))
    end

    example { expect(last_response.status).to eq 403 }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'error',
        'error_type' => 'insufficient_access',
        'error_message' => 'operation requires write access to env_var',
        'permission' => 'write',
        'resource_type' => 'env_var',
        'env_var' => {
          '@type' => 'env_var',
          '@href' => "/v3/repo/#{repo.id}/env_var/#{env_var[:id]}",
          '@representation' => 'minimal',
          'id' => env_var[:id],
          'name' => env_var[:name],
          'public' => env_var[:public],
          'branch' => env_var[:branch]
        }
      )
    end
  end

  describe 'authenticated, existing repo, existing env var, correct permissions' do
    let(:params) do
      {
        'env_var.name' => 'QUX'
      }
    end

    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
      repo.update(settings: { env_vars: [env_var], foo: 'bar' })
      patch("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}", JSON.generate(params), auth_headers.merge(json_headers))
    end

    example { expect(last_response.status).to eq 200 }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'env_var',
        '@href' => "/v3/repo/#{repo.id}/env_var/#{env_var[:id]}",
        '@representation' => 'standard',
        '@permissions' => { 'read' => true, 'write' => true },
        'id' => env_var[:id],
        'name' => params['env_var.name'],
        'value' => env_var[:value].decrypt,
        'public' => env_var[:public],
        'branch' => env_var[:branch]
      )
    end
    example 'persists changes' do
      expect(repo.reload.settings['env_vars'].first['name']).to eq 'QUX'
    end
    example 'does not clobber other settings' do
      expect(repo.reload.settings['foo']).to eq 'bar'
    end
    example 'audit is created' do
      expect(Travis::API::V3::Models::Audit.last.source_id).to eq(repo.id)
      expect(Travis::API::V3::Models::Audit.last.source_type).to eq('Repository')
    end
  end

  context do
    let(:params) { { 'env_var.name' => 'QUX' } }
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }

    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before { patch("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}", JSON.generate(params), auth_headers.merge(json_headers)) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before { repo.update(migration_status: "migrated") }
      before { patch("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}", JSON.generate(params), auth_headers.merge(json_headers)) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
