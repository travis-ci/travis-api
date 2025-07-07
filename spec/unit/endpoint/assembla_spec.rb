require 'spec_helper'
require 'rack/test'
require 'jwt'

RSpec.describe Travis::Api::App::Endpoint::Assembla, set_app: true do
  include Rack::Test::Methods

  let(:jwt_secret) { 'testsecret' }
  let(:payload) do
    {
      'name' => 'Test User',
      'email' => 'test@example.com',
      'login' => 'testuser',
      'space_id' => 'space123'
    }
  end
  let(:token) { JWT.encode(payload, jwt_secret, 'HS256') }

  before do
    Travis.config[:deep_integration_enabled] = true
    Travis.config[:assembla_clusters] = 'cluster1'
    Travis.config[:assembla_jwt_secret] = jwt_secret

    header 'X_ASSEMBLA_CLUSTER', 'cluster1'
  end

  describe 'POST /assembla/login' do
    context 'with valid JWT' do
      before do
        allow_any_instance_of(Travis::RemoteVCS::User).to receive(:sync).and_return(true)
        allow_any_instance_of(Travis::API::V3::BillingClient).to receive(:create_v2_subscription).and_return(true)
      end

      it 'returns user info and token' do
        header 'Authorization', "Bearer #{token}"
        post '/assembla/login'
        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)
        expect(body['login']).to eq('testuser')
        expect(body['token']).to be_present
        expect(body['status']).to eq('signed_in')
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

    context 'when user sync fails' do
      before do
        allow(::User).to receive(:first_or_create!).and_return(double('User', id: 1, login: 'testuser', token: 'abc123'))
        allow_any_instance_of(Travis::RemoteVCS::User).to receive(:sync).and_raise(StandardError.new('sync error'))
      end

      it 'returns 500 with error message' do
        header 'Authorization', "Bearer #{token}"
        post '/assembla/login'
        expect(last_response.status).to eq(500)
        expect(last_response.body).to include('User sync failed')
        expect(last_response.body).to include('sync error')
      end
    end

    context 'when integration is not enabled' do
      before { Travis.config[:deep_integration_enabled] = false }
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

    context 'with missing required fields in JWT payload' do
      let(:payload) do
        {
          'name' => 'Test User',
          'login' => 'testuser',
          'space_id' => 'space123' # 'email' is missing
        }
      end
      let(:token) { JWT.encode(payload, jwt_secret, 'HS256') }

      it 'returns 400 with missing fields' do
        header 'Authorization', "Bearer #{token}"
        post '/assembla/login'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to include('Missing required fields')
        expect(last_response.body).to include('email')
      end
    end

    context 'with expired JWT token' do
      let(:payload) do
        {
          'name' => 'Test User',
          'email' => 'test@example.com',
          'login' => 'testuser',
          'space_id' => 'space123',
          'exp' => (Time.now.to_i - 60)
        }
      end
      let(:token) { JWT.encode(payload, jwt_secret, 'HS256') }

      it 'returns 401 with expired error' do
        header 'Authorization', "Bearer #{token}"
        post '/assembla/login'
        expect(last_response.status).to eq(401)
        expect(last_response.body).to match(/expired|exp/i)
      end
    end
  end
end
