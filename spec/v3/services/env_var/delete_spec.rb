require 'spec_helper'

describe Travis::API::V3::Services::EnvVar::Delete, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:env_var) { { id: 'abc', name: 'FOO', value: Travis::Settings::EncryptedValue.new('bar'), public: true, branch: 'foo', repository_id: repo.id } }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe 'not authenticated' do
    before { delete("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}") }
    include_examples 'not authenticated'
  end

  describe 'authenticated, wrong permissions' do

    let(:authorization) { { 'permissions' => ['repository_settings_read'] } }
    before do
      repo.update(settings: { env_vars: [env_var] })
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
      delete("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}", {}, auth_headers)
    end
    example { expect(last_response.status).to eq 403 }
    example do
      expect(JSON.load(last_response.body)).to eq(
        '@type' => 'error',
        'error_type' => 'insufficient_access',
        'error_message' => 'operation requires write access to env_var',
        'resource_type' => 'env_var',
        'permission' => 'write',
        'env_var' => {
          '@type' => 'env_var',
          '@href' => "/v3/repo/#{repo.id}/env_var/#{env_var[:id]}",
          '@representation' => 'minimal',
          'id' => env_var[:id],
          'name' => env_var[:name],
          'public' => true,
          'branch' => env_var[:branch]
        }
      )
    end
  end

  context 'authenticated, right permissions' do
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }

    describe 'missing repo' do
      before { delete("/v3/repo/999999999/env_var/foo", {}, auth_headers) }
      include_examples 'missing repo'
    end

    describe 'existing repo, missing env var' do
      before { delete("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}", {}, auth_headers) }
      include_examples 'missing env_var'
    end

    describe 'existing repo, existing env var' do
      before do
        repo.update(settings: { env_vars: [env_var], foo: 'bar' })
        delete("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}", {}, auth_headers)
      end

      example { expect(last_response.status).to eq 204 }
      example { expect(last_response.body).to be_empty }
      example 'persists changes' do
        expect(repo.reload.env_vars.find(env_var[:id])).to be_nil
      end
      example 'does not clobber other settings' do
        expect(repo.reload.settings['foo']).to eq 'bar'
      end
      example 'audit is created' do
        expect(Travis::API::V3::Models::Audit.last.source_id).to eq(repo.id)
        expect(Travis::API::V3::Models::Audit.last.source_type).to eq('Repository')
      end
    end
  end

  context do
    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
      before { delete("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}", {}, auth_headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before  { repo.update(migration_status: "migrated") }
      before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
      before { delete("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}", {}, auth_headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
