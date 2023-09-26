require 'spec_helper'
require 'openssl'

describe Travis::API::V3::Services::KeyPair::Find, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:key) { OpenSSL::PKey::RSA.generate(4096) }
  let(:key_pair) { { description: 'foo key pair', value: Travis::Settings::EncryptedValue.new(key.to_pem), repository_id: repo.id } }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }


  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  shared_examples 'paid' do
    describe 'not authenticated' do
      before { get("/v3/repo/#{repo.id}/key_pair") }
      include_examples 'not authenticated'
    end

    context 'authenticated' do
      describe 'missing repo' do
        before { get('/v3/repo/999999999/key_pair', {}, auth_headers) }
        include_examples 'missing repo'
      end

      describe 'existing repo, no key pair' do
        before do
          Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
          get("/v3/repo/#{repo.id}/key_pair", {}, auth_headers)
        end

        example { expect(last_response.status).to eq 404 }
        example do
          expect(JSON.parse(last_response.body)).to eq(
            '@type' => 'error',
            'error_message' => 'key_pair not found (or insufficient access)',
            'error_type' => 'not_found',
            'resource_type' => 'key_pair'
          )
        end
      end

      describe 'existing repo, existing key pair' do
        before do
          Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
          repo.update(settings: { ssh_key: key_pair })
          get("/v3/repo/#{repo.id}/key_pair", {}, auth_headers)
        end

        let(:authorization) { { 'permissions' => ['repository_settings_read'] } }
        example { expect(last_response.status).to eq 200 }
        example do
          expect(JSON.parse(last_response.body)).to eq(
            '@type' => 'key_pair',
            '@href' => "/v3/repo/#{repo.id}/key_pair",
            '@representation' => 'standard',
            '@permissions' => { 'read' => true, 'write' => false },
            'description' => 'foo key pair',
            'fingerprint' => Travis::API::V3::Models::Fingerprint.calculate(key.to_pem),
            'public_key' => key.public_key.to_s
          )
        end
      end
    end
  end

  context 'enterprise' do
    around(:each) do |example|
      Travis.config.enterprise = true
      example.run
      Travis.config.enterprise = nil
    end

    include_examples 'paid'
  end

  context 'private repo' do
    before { repo.update(private: true) }

    include_examples 'paid'
  end

  context 'non-paid' do
    describe 'feature not available' do
      before { get("/v3/repo/#{repo.id}/key_pair", {}, auth_headers) }

      include_examples 'paid feature error'
    end
  end
end
