require 'spec_helper'

describe Travis::API::V3::Services::BetaMigrationRequests::Find, set_app: true do
  let!(:user)  { Factory(:user) }
  let(:beta_migration_request) { Factory(:beta_migration_request, owner_id: user.id) }
  let(:org1) { Factory(:org_v3) }
  let(:org2) { Factory(:org_v3) }

  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let!(:other_user) { Factory(:user, login: 'noone') }

  let(:response_hash) do
    {
      '@type'                   => 'beta_migration_requests',
      '@href'                   => "/v3/user/#{user.id}/beta_migration_requests",
      '@representation'         => 'standard',
      'beta_migration_requests' => [
        {
          '@type'           => 'beta_migration_request',
          '@representation' => 'standard',
          'id'              => beta_migration_request.id,
          'owner_id'        => beta_migration_request.owner_id,
          'owner_name'      => beta_migration_request.owner_name,
          'owner_type'      => beta_migration_request.owner_type,
          'accepted_at'     => beta_migration_request.accepted_at,
          'organizations'   => [org1.id, org2.id]
        }
      ]
    }
  end

  before { Travis.config.host = 'travis-ci.com' }

  describe 'not authenticated' do
    before { get("/v3/user/#{user.id}/beta_migration_requests") }
    include_examples 'not authenticated'
  end

  describe 'authenticated, missing user' do
    before { get("/v3/user/999999999/beta_migration_requests", {}, auth_headers) }
    include_examples 'missing user'
  end

  describe 'authenticated, different user\'s beta migration requests' do
    before do
      get("/v3/user/#{other_user.id}/beta_migration_requests", {}, auth_headers)
    end
    example { expect(last_response.status).to eq(404) }
  end

  describe 'authenticated, existing user, no beta migration requests' do
    before do
      get("/v3/user/#{user.id}/beta_migration_requests", {}, auth_headers)
    end
    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type'                   => 'beta_migration_requests',
        '@href'                   => "/v3/user/#{user.id}/beta_migration_requests",
        '@representation'         => 'standard',
        'beta_migration_requests' => []
      )
    end
  end

  describe 'authenticated, existing user, existing beta migration requests' do
    before do
      beta_migration_request
      beta_migration_request.organizations << org1
      beta_migration_request.organizations << org2
      beta_migration_request.save!

      get("/v3/user/#{user.id}/beta_migration_requests", {}, auth_headers)
    end
    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(response_hash)
    end

    context 'when it is .org API' do
      before do
        Travis.config.host = 'travis-ci.org'
        stub_request(:get, "#{Travis.config.api_com_url}/v3/user/#{user.id}/beta_migration_requests").to_return(status: 200, body: response_hash.to_json)
      end

      it 'fetches beta_migration_requests from .com API' do
        get("/v3/user/#{user.id}/beta_migration_requests", {}, auth_headers)
        expect(JSON.load(body)).to eq(response_hash)
      end
    end
  end
end
