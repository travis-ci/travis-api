require 'spec_helper'

describe Travis::API::V3::Services::EnvVars::Create do
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

  describe 'authenticated, existing repo, env var already exists' do
    let(:params) do
      {
        'env_var.name' => 'FOO',
        'env_var.value' => 'bar',
        'env_var.public' => false
      }
    end

    before do
      repo.update_attributes(settings: JSON.generate(env_vars: [{ id: 'abc', name: 'FOO', value: 'bar', public: false }]))
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
    let(:params) do
      {
        'env_var.name' => 'FOO',
        'env_var.value' => 'bar',
        'env_var.public' => false
      }
    end

    before { post("/v3/repo/#{repo.id}/env_vars", JSON.generate(params), auth_headers.merge(json_headers)) }

    example { expect(last_response.status).to eq 201 }
    example do
      response = JSON.load(body)
      expect(response).to include(
        '@type' => 'env_var',
        '@representation' => 'standard',
        'name' => 'FOO',
        'value' => 'bar',
        'public' => false
      )
      expect(response).to include('@href', 'id')
    end
  end
end
