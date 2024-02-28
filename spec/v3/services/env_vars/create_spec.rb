require 'spec_helper'

describe Travis::API::V3::Services::EnvVars::Create, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe 'not authenticated' do
    before { post("/v3/repo/#{repo.id}/env_vars", {}) }
    include_examples 'not authenticated'
  end

  describe 'authenticated, repo missing' do
    before { post("/v3/repo/99999999/env_vars", {}, auth_headers) }
    include_examples 'missing repo'
  end

  describe 'authenticated, existing repo, wrong permissions' do
    let(:authorization) { { 'permissions' => ['repository_settings_read'] } }
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
      repo.update(settings: { env_vars: [{ id: 'abc', name: 'FOO', value: Travis::Settings::EncryptedValue.new('bar'), public: false }] })
      post("/v3/repo/#{repo.id}/env_vars", JSON.generate({}), auth_headers.merge(json_headers))
    end

    example { expect(last_response.status).to eq 403 }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'error',
        'error_message' => 'operation requires create_env_var access to repository',
        'error_type' => 'insufficient_access',
        'permission' => 'create_env_var',
        'resource_type' => 'repository',
        'repository' => {
          '@type' => 'repository',
          '@href' => "/v3/repo/#{repo.id}",
          '@representation' => 'minimal',
          'id' => repo.id,
          'name' => repo.name,
          'slug' => repo.slug
        }
      )
    end
  end

  describe 'authenticated, existing repo, env var name is empty' do
    let(:params) do
      {
        'env_var.name' => '',
        'env_var.value' => 'bar',
        'env_var.public' => false
      }
    end

    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
      post("/v3/repo/#{repo.id}/env_vars", JSON.generate(params), auth_headers.merge(json_headers))
    end

    example { expect(last_response.status).to eq 422 }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'error',
        'error_message' => 'Variable name is required',
        'error_type' => 'unprocessable_entity'
      )
    end
    example { expect(repo.reload.env_vars.count).to eq(0) }
  end

  describe 'authenticated, existing repo, env var already exists' do
    let(:params) do
      {
        'env_var.name' => 'FOO',
        'env_var.value' => 'bar',
        'env_var.public' => false
      }
    end

    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
      repo.update(settings: { env_vars: [{ id: 'abc', name: 'FOO', value: Travis::Settings::EncryptedValue.new('bar'), public: false }] })
      post("/v3/repo/#{repo.id}/env_vars", JSON.generate(params), auth_headers.merge(json_headers))
    end

    example { expect(last_response.status).to eq 409 }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'error',
        'error_message' => 'resource already exists',
        'error_type' => 'duplicate_resource'
      )
    end
    example { expect(repo.reload.env_vars.count).to eq(1) }
  end

  describe 'authenticated, existing repo, env var is new' do
    describe 'private' do
      let(:params) do
        {
          'env_var.name' => 'FOO',
          'env_var.value' => 'bar',
          'env_var.public' => false
        }
      end

      before do
        Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
        post("/v3/repo/#{repo.id}/env_vars", JSON.generate(params), auth_headers.merge(json_headers))
      end

      example { expect(last_response.status).to eq 201 }
      example do
        response = JSON.load(body)
        expect(response).to include(
          '@type' => 'env_var',
          '@representation' => 'standard',
          'name' => 'FOO',
          'public' => false
        )
        expect(response).to include('@href', 'id')
      end
      example 'persists changes' do
        expect(repo.reload.settings['env_vars'].first['name']).to eq 'FOO'
      end
      example 'persists repository id' do
        expect(repo.reload.settings['env_vars'].first['repository_id']).to eq repo.id
      end
      example 'audit is created' do
        expect(Travis::API::V3::Models::Audit.last.source_id).to eq(repo.id)
        expect(Travis::API::V3::Models::Audit.last.source_type).to eq('Repository')
        expect(Travis::API::V3::Models::Audit.last.source_changes).to eq({"settings"=>{"env_vars"=>{"created"=> "{\"name\"=>\"FOO\", \"public\"=>false}"}}}) 
      end
    end

    describe 'public' do
      let(:params) do
        {
          'env_var.name' => 'FOO',
          'env_var.value' => 'bar',
          'env_var.public' => true
        }
      end

      before do
        Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
        post("/v3/repo/#{repo.id}/env_vars", JSON.generate(params), auth_headers.merge(json_headers))
      end

      example { expect(last_response.status).to eq 201 }
      example do
        response = JSON.load(body)
        expect(response).to include(
          '@type' => 'env_var',
          '@representation' => 'standard',
          'name' => 'FOO',
          'value' => 'bar',
          'public' => true
        )
        expect(response).to include('@href', 'id')
      end
    end
  end

  context do
    let(:params) { { 'env_var.name' => 'QUX' } }
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }

    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before { post("/v3/repo/#{repo.id}/env_vars", JSON.generate(params), auth_headers.merge(json_headers)) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before { repo.update(migration_status: "migrated") }
      before { post("/v3/repo/#{repo.id}/env_vars", JSON.generate(params), auth_headers.merge(json_headers)) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
