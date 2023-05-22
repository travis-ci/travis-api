# frozen_string_literal: true

require 'spec_helper'

describe Travis::API::V3::Services::Storage::Delete, set_app: true do
  let(:user)    { FactoryBot.create(:user) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:id) { 'billing_wizard_state' }
  let(:parsed_body) { JSON.load(last_response.body) }

  describe 'not authenticated' do
    before { delete("/v3/storage/#{id}") }
    example do
      expect(last_response.status).to eq 403
    end
  end

  describe 'authenticated, other user' do
    let(:other_user) { FactoryBot.create(:user, login: 'noone') }
    let(:token) { Travis::Api::App::AccessToken.create(user: other_user, app_id: 1) }
    let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before { delete("/v3/storage/#{id}", auth_headers) }
    example do
      expect(last_response.status).to eq 403
    end
  end

  context 'authenticated, right permissions' do
    describe 'existing user' do
      before do
        delete("/v3/storage/#{id}", {}, auth_headers)
      end
      example do
        expect(last_response.status).to eq 200
        expect(parsed_body).to eql_json({
                                          '@type' => 'storage',
                                          '@representation' => 'standard',
                                          'id' => 'billing_wizard_state',
                                          'value' => 0
                                        })
      end
    end
  end
end
