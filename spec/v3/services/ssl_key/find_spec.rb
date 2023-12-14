require 'spec_helper'

describe Travis::API::V3::Services::SslKey::Find, set_app: true do
  let(:repo) do
    Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create.tap do |repo|
      key = repo.key
      key.generate_keys!
      key.save!
    end
  end
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  let(:authorization) { { 'permissions' => ['repository_settings_read'] } }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe 'not authenticated' do
    before { get("/v3/repo/#{repo.id}/key_pair/generated") }
    include_examples 'not authenticated'
  end

  context 'authenticated' do
    describe 'missing repo' do
      before { get("/v3/repo/999999999/key_pair/generated", {}, auth_headers) }
      include_examples 'missing repo'
    end

    describe 'existing repo, no key' do
      before do
        repo.key.destroy
        get("/v3/repo/#{repo.id}/key_pair/generated", {}, auth_headers)
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

    describe 'existing repo, existing key' do
      before { get("/v3/repo/#{repo.id}/key_pair/generated", {}, auth_headers) }
      example { expect(last_response.status).to eq 200 }
      example do
        expect(JSON.parse(last_response.body)).to eq(
          '@type' => 'key_pair',
          '@href' => "/v3/repo/#{repo.id}/key_pair/generated",
          '@representation' => 'standard',
          '@permissions' => { 'read' => true, 'write' => false },
          'description' => 'This key pair was generated by Travis CI',
          'public_key' => repo.key.public_key,
          'fingerprint' => repo.key.fingerprint
        )
      end
    end
  end
end
