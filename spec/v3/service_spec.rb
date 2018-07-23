require 'spec_helper'

require 'travis/api/v3/routes'
require 'travis/api/v3/service'
require 'travis/api/v3/services'

module Travis::API::V3
  module Services
    Examples = Module.new { extend Services }
  end

  class Services::Examples::Find < Service
    def run!
      head
    end
  end

  module Routes
    resource :examples do
      route '/examples'
      get :find
    end
  end
end

describe Travis::API::V3::Services::Examples::Find, set_app: true do
  let(:token) { Travis::Api::App::AccessToken.create(user: User.last, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  context 'without forcing authentication' do
    it 'allows unauthenticated access' do
      get '/v3/examples'
      expect(last_response.status).to eq 200
    end
  end

  context 'when forcing authentication' do
    before { Travis.config.force_authentication = true }
    after { Travis.config.force_authentication = false }

    it 'does not allow access without authentication' do
      get '/v3/examples'
      expect(last_response.status).to eq 403
    end

    it 'does allow access with authentication' do
      get '/v3/examples', {}, auth_headers
      expect(last_response.status).to eq 200
    end

    it 'does allow access with log token' do
      get '/v3/examples?log.token=abc123'
      expect(last_response.status).to eq 200
    end
  end
end
