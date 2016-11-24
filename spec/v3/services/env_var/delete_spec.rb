require 'spec_helper'

describe Travis::API::V3::Services::EnvVar::Delete, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:env_var) { { id: 'abc', name: 'FOO', value: Travis::Settings::EncryptedValue.new('bar'), public: true, repository_id: repo.id } }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  describe 'not authenticated' do
    before { delete("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}") }
    include_examples 'not authenticated'
  end

  describe 'authenticated, wrong permissions' do
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
      delete("/v3/repo/#{repo.id}/env_var/foo", {}, auth_headers)
    end
    example { expect(last_response.status).to eq 403 }
    example do
      expect(JSON.load(last_response.body)).to eq(
        '@type' => 'error',
        'error_type' => 'insufficient_access',
        'error_message' => 'operation requires change_env_vars access to repository',
        'resource_type' => 'repository',
        'permission' => 'change_env_vars',
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
        repo.update_attributes(settings: JSON.generate(env_vars: [env_var], foo: 'bar'))
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
    end
  end
end
