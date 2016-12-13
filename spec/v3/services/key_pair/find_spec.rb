require 'spec_helper'

describe Travis::API::V3::Services::KeyPair::Find, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:key_pair) { { 'id' => 'abc123', 'repository_id' => repo.id } }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

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
      before { get("/v3/repo/#{repo.id}/key_pair", {}, auth_headers) }

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
        repo.update_attribute(:settings, JSON.generate('ssh_key' => key_pair))
        get("/v3/repo/#{repo.id}/key_pair", {}, auth_headers)
      end

      example { expect(last_response.status).to eq 200 }
      example do
        expect(JSON.parse(last_response.body)).to eq(
          '@type' => 'key_pair',
          '@href' => "/v3/repo/#{repo.id}/key_pair",
          '@representation' => 'standard',
          'id' => 'abc123'
        )
      end
    end
  end
end
