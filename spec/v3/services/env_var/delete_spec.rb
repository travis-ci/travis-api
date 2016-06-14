require 'spec_helper'

describe Travis::API::V3::Services::EnvVar::Delete do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:env_var) { { id: 'abc', name: 'FOO', value: 'bar', public: true, repository_id: repo.id } }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  describe 'not authenticated' do
    before { delete("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}") }
    include_examples 'not authenticated'
  end

  describe 'authenticated, missing repo' do
    before { delete("/v3/repo/999999999/env_var/foo", {}, auth_headers) }
    include_examples 'missing repo'
  end

  describe 'authenticated, missing repo, missing env var' do
    before { delete("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}", {}, auth_headers) }
    include_examples 'missing env_var'
  end

  describe 'authenticated, missing repo, existing env var' do
    before do
      repo.update_attributes(settings: JSON.generate(env_vars: [env_var]))
      delete("/v3/repo/#{repo.id}/env_var/#{env_var[:id]}", {}, auth_headers)
    end

    example { expect(last_response.status).to eq 200 }
    example { pending 'should we return an empty body here?' }
  end
end
