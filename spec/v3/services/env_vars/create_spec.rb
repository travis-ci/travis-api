require 'spec_helper'

describe Travis::API::V3::Services::EnvVars::Create, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  describe 'not authenticated' do
    before { post("/v3/repo/#{repo.id}/env_vars", {}) }
    include_examples 'not authenticated'
  end

  describe 'authenticated, repo missing' do
    before { post("/v3/repo/99999999/env_vars", {}, auth_headers) }
    include_examples 'missing repo'
  end

  describe 'authenticated, existing repo, wrong permissions' do
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
      repo.update_attributes(settings: { env_vars: [{ id: 'abc', name: 'FOO', value: Travis::Settings::EncryptedValue.new('bar'), public: false }] })
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
      repo.update_attributes(settings: { env_vars: [{ id: 'abc', name: 'FOO', value: Travis::Settings::EncryptedValue.new('bar'), public: false }] })
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
end
