require 'spec_helper'

describe Travis::API::V3::Services::EnvVars::ForRepository do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:env_var) { { id: 'abc', name: 'FOO', value: 'bar', public: true, repository_id: repo.id } }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  
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
    before do
      repo.update_attributes(settings: JSON.generate(env_vars: [env_var]))
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
            'id' => env_var[:id],
            'name' => env_var[:name],
            'value' => env_var[:value],
            'public' => env_var[:public]
          }
        ]
      )
    end
  end
end
