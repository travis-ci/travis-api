require 'spec_helper'

describe Travis::API::V3::Services::KeyPairs::ForRepository, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:key_pair) { { 'id' => 'abc123' } }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  describe 'not authenticated' do
    before { get("/v3/repo/#{repo.id}/key_pairs") }
    include_examples 'not authenticated'
  end

  context 'authenticated' do
    describe 'missing repo' do
      before { get('/v3/repo/999999999/key_pairs', {}, auth_headers) }
      include_examples 'missing repo'
    end

    describe 'existing repo, no key pairs' do
      before { get("/v3/repo/#{repo.id}/key_pairs", {}, auth_headers) }

      example { expect(last_response.status).to eq 200 }
      example do
        expect(JSON.parse(last_response.body)).to eq(
          '@type' => 'key_pairs',
          '@href' => "/v3/repo/#{repo.id}/key_pairs",
          '@representation' => 'standard',
          'key_pairs' => []
        )
      end
    end

    describe 'existing repo, existing key pairs' do
      before do
        repo.update_attribute(:settings, JSON.generate('ssh_keys' => [key_pair]))
        get("/v3/repo/#{repo.id}/key_pairs", {}, auth_headers)
      end

      example { expect(last_response.status).to eq 200 }
      example do
        expect(JSON.parse(last_response.body)).to eq(
          '@type' => 'key_pairs',
          '@href' => "/v3/repo/#{repo.id}/key_pairs",
          '@representation' => 'standard',
          'key_pairs' => [
            { '@type' => 'key_pair', '@representation' => 'standard', 'id' => 'abc123' }
          ]
        )
      end
    end
  end
end
