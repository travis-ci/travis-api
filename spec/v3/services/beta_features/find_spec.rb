require 'spec_helper'

describe Travis::API::V3::Services::BetaFeatures::Find, set_app: true do
  let(:user)  { Travis::API::V3::Models::User.where(login: 'svenfuchs').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:beta_feature) { Travis::API::V3::Models::BetaFeature.create(name: 'FOO3', description: "Bar Baz.", feedback_url: "http://thisisgreat.com")}
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:other_user) { FactoryBot.create(:user, login: 'noone') }

  describe 'not authenticated' do
    before { get("/v3/user/#{user.id}/beta_features") }
    include_examples 'not authenticated'
  end

  describe 'authenticated, missing user' do
    before { get("/v3/user/999999999/beta_features", {}, auth_headers) }
    include_examples 'missing user'
  end

  describe 'authenticated, different user\'s beta features' do
    before do
      get("/v3/user/#{other_user.id}/beta_features", {}, auth_headers)
    end
    example { expect(last_response.status).to eq(404) }
  end

  describe 'authenticated, existing user, public_mode disabled' do
    before { Travis.config.public_mode = false }
    after { Travis.config.public_mode = true }
    before { Travis::Features.deactivate_owner(:public_mode, user) }

    before do
      get("/v3/user/#{user.id}/beta_features", {}, auth_headers)
    end
    example { expect(last_response.status).to eq(200) }
  end

  describe 'authenticated, existing user, no beta features' do
    before do
      get("/v3/user/#{user.id}/beta_features", {}, auth_headers)
    end
    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'beta_features',
        '@href' => "/v3/user/#{user.id}/beta_features",
        '@representation' => 'standard',
        'beta_features' => []
      )
    end
  end

  describe 'authenticated, existing user, existing beta features' do
    before do
      beta_feature
      get("/v3/user/#{user.id}/beta_features", {}, auth_headers)
    end
    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'beta_features',
        '@href' => "/v3/user/#{user.id}/beta_features",
        '@representation' => 'standard',
        'beta_features' => [
          {
            '@type' => 'beta_feature',
            '@representation' => 'standard',
            'id' => beta_feature.id,
            'name' => beta_feature.name,
            'description' => beta_feature.description,
            'feedback_url' => beta_feature.feedback_url,
            'enabled' => beta_feature.enabled
          }
        ]
      )
    end
    describe 'authenticated, existing user, existing beta features and user beta features' do
      let(:user_beta_feature){Travis::API::V3::Models::UserBetaFeature.create(user: user, beta_feature: beta_feature, enabled: true)}
      before do
        user_beta_feature
        get("/v3/user/#{user.id}/beta_features", {}, auth_headers)
      end
      example { expect(last_response.status).to eq(200) }
      example do
        expect(JSON.load(body)).to eq(
          '@type' => 'beta_features',
          '@href' => "/v3/user/#{user.id}/beta_features",
          '@representation' => 'standard',
          'beta_features' => [
            {
              '@type' => 'beta_feature',
              '@representation' => 'standard',
              'id' => beta_feature.id,
              'name' => beta_feature.name,
              'description' => beta_feature.description,
              'feedback_url' => beta_feature.feedback_url,
              'enabled' => user_beta_feature.enabled
            }
          ]
        )
      end
    end
  end
end
