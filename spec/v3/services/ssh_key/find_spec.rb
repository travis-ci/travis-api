require 'spec_helper'

describe Travis::API::V3::Services::SshKey::Find, set_app: true do
  let(:repo) do
    Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create.tap do |repo|
      repo.create_key.tap { |key| key.generate_keys!; key.save! }
    end
  end
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  describe 'not authenticated' do
    before { get("/v3/repo/#{repo.id}/ssh_key") }
    include_examples 'not authenticated'
  end

  describe 'authenticated, missing repo' do
    before { get("/v3/repo/999999999/ssh_key", {}, auth_headers) }
    include_examples 'missing repo'
  end

  describe 'authenticated, existing repo, no key' do
    before do
      repo.key.destroy
      get("/v3/repo/#{repo.id}/ssh_key", {}, auth_headers)
    end

    example { expect(last_response.status).to eq 404 }
    example do
      expect(JSON.parse(last_response.body)).to eq(
        '@type' => 'error',
        'error_message' => 'ssh_key not found (or insufficient access)',
        'error_type' => 'not_found',
        'resource_type' => 'ssh_key'
      )
    end
  end

  describe 'authenticated, existing repo, existing key' do
    before { get("/v3/repo/#{repo.id}/ssh_key", {}, auth_headers) }
    example { expect(last_response.status).to eq 200 }
    example do
      expect(JSON.parse(last_response.body)).to eq(
        '@type' => 'ssh_key',
        '@href' => "/v3/repo/#{repo.id}/ssh_key",
        '@representation' => 'standard',
        'id' => repo.key.id,
        'public_key' => repo.key.public_key,
        'fingerprint' => repo.key.fingerprint
      )
    end
  end
end
