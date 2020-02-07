require 'spec_helper'

describe Travis::API::V3::Services::BetaMigrationRequests::Find, set_app: true do
  let!(:user)  { FactoryBot.create(:user) }
  let(:beta_migration_request) { FactoryBot.create(:beta_migration_request, owner_id: user.id) }
  let(:org1) { FactoryBot.create(:org_v3) }
  let(:org2) { FactoryBot.create(:org_v3) }

  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let!(:other_user) { FactoryBot.create(:user, login: 'noone') }

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
          'organizations'   => [org1.id, org2.id],
          'organizations_logins'  => [org1.login, org2.login]
        }
      ]
    }
  end

  let(:empty_response_hash) do
    {
      '@type'                   => 'beta_migration_requests',
      '@href'                   => "/v3/user/#{user.id}/beta_migration_requests",
      '@representation'         => 'standard',
      'beta_migration_requests' => []
    }
  end

  before do
    Travis.config.applications[:api_org] = { token: 'sometoken', full_access: true }
  end

  after do
    Travis.config.applications.delete(:api_org)
  end

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
      stub_request(:get, "#{Travis.config.api_com_url}/v3/beta_migration_requests?user_login=svenfuchs").to_return(status: 200, body: empty_response_hash.to_json)
      get("/v3/user/#{other_user.id}/beta_migration_requests", {}, auth_headers)
    end
    example { expect(last_response.status).to eq(404) }
  end

  describe 'authenticated, existing user, no beta migration requests' do
    before do
      stub_request(:get, "#{Travis.config.api_com_url}/v3/beta_migration_requests?user_login=svenfuchs").to_return(status: 200, body: empty_response_hash.to_json)
      get("/v3/user/#{user.id}/beta_migration_requests", {}, auth_headers)
    end
    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(empty_response_hash)
    end
  end

  describe 'authenticated, existing user, existing beta migration requests' do
    before do
      beta_migration_request
      beta_migration_request.organizations << org1
      beta_migration_request.organizations << org2
      beta_migration_request.save!
      stub_request(:get, "#{Travis.config.api_com_url}/v3/beta_migration_requests?user_login=svenfuchs").to_return(status: 200, body: response_hash.to_json)
      get("/v3/user/#{user.id}/beta_migration_requests", {}, auth_headers)
    end

    let(:parsed_body) { JSON.load(body) }
    let(:beta_request) { parsed_body['beta_migration_requests'].first }

    example { expect(last_response.status).to eq(200) }
    example do
      expect(beta_request['owner_id']).to eq(beta_migration_request.owner_id)
      expect(beta_request['owner_type']).to eq(beta_migration_request.owner_type)
      expect(beta_request['owner_name']).to eq(beta_migration_request.owner_name)
      expect(beta_request['organizations']).to match_array([org1.id, org2.id])
      expect(beta_request['organizations_logins']).to match_array([org1.login, org2.login])
    end
  end
end
