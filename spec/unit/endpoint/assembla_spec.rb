require 'spec_helper'
require 'rack/test'
require 'jwt'

RSpec.describe Travis::Api::App::Endpoint::Assembla, set_app: true do
  include Rack::Test::Methods

  let(:jwt_secret) { 'assembla_jwt_secret' }
  let(:payload) do
    {
      'name' => 'Test User',
      'email' => 'test@example.com',
      'login' => 'testuser',
      'space_id' => 'space123',
      'id' => 'assembla_vcs_user_id',
      'access_token' => 'test_access_token',
      'refresh_token' => 'test_refresh_token'
    }
  end
  let(:token) { JWT.encode(payload, jwt_secret, 'HS256') }
  let(:user) { double('User', id: 1, login: 'testuser', token: 'abc123', name: 'Test User', email: 'test@example.com', organizations: organizations) }
  let(:organization) { double('Organization', id: 1) }
  let(:organizations) { double('Organizations') }
  let(:subscription_response) { { 'status' => 'subscribed' } }
  let(:assembla_cluster) { 'eu' }
  let!(:original_deep_integration_enabled) { Travis.config[:deep_integration_enabled] }

  before do
    Travis.config[:deep_integration_enabled] = true

    header 'X_ASSEMBLA_CLUSTER', assembla_cluster
  end

  after do
    Travis.config[:deep_integration_enabled] = original_deep_integration_enabled
  end

  describe 'POST /assembla/login' do
    context 'with valid JWT' do
      let(:service) { instance_double(Travis::Services::AssemblaUserService) }
      let(:remote_vcs_user) { instance_double(Travis::RemoteVCS::User) }
      let(:billing_client) { instance_double(Travis::API::V3::BillingClient) }

      before do
        allow(Travis::Services::AssemblaUserService).to receive(:new).with(payload).and_return(service)
        allow(service).to receive(:find_or_create_user).and_return(user)
        allow(service).to receive(:find_or_create_organization).with(user).and_return(organization)
        allow(service).to receive(:create_org_subscription).with(user, organization.id).and_return(subscription_response)
      end

      it 'creates user, organization and subscription' do
        header 'Authorization', "Bearer #{token}"
        post '/assembla/login'

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)
        expect(body['login']).to eq(user.login)
        expect(body['token']).to eq(user.token)
      end
    end

    context 'with missing JWT' do
      it 'returns 401' do
        post '/assembla/login'
        expect(last_response.status).to eq(401)
        expect(last_response.body).to include('Missing JWT')
      end
    end

    context 'with invalid JWT' do
      it 'returns 401' do
        header 'Authorization', 'Bearer invalidtoken'
        post '/assembla/login'
        expect(last_response.status).to eq(401)
        expect(last_response.body).to include('Invalid JWT')
      end
    end

    context 'with missing required fields' do
      let(:invalid_payload) { payload.tap { |p| p.delete('email') } }
      let(:invalid_token) { JWT.encode(invalid_payload, jwt_secret, 'HS256') }

      it 'returns 400 with missing fields' do
        header 'Authorization', "Bearer #{invalid_token}"
        post '/assembla/login'
        
        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        expect(body['error']).to eq('Missing required fields')
        expect(body['missing']).to include('email')
      end
    end

    context 'when integration is not enabled' do
      
      before { Travis.config[:deep_integration_enabled] = original_deep_integration_enabled }
      after { Travis.config[:deep_integration_enabled] = true }
      
      it 'returns 403' do
        header 'Authorization', "Bearer #{token}"
        post '/assembla/login'
        expect(last_response.status).to eq(403)
        expect(last_response.body).to include('Deep integration not enabled')
      end
    end

    context 'when cluster is invalid' do
      before { header 'X_ASSEMBLA_CLUSTER', 'invalid-cluster' }
      
      it 'returns 403' do
        header 'Authorization', "Bearer #{token}"
        post '/assembla/login'
        expect(last_response.status).to eq(403)
        expect(last_response.body).to include('Invalid ASM cluster')
      end
    end
  end
end
