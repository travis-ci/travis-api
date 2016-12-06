require 'spec_helper'

describe Travis::API::V3::Services::BetaFeature::Update, set_app: true do
  let(:user)  { Travis::API::V3::Models::User.where(login: 'svenfuchs').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:beta_feature) { Travis::API::V3::Models::BetaFeature.create(name: 'FOO2', description: "Bar Baz.", feedback_url: "http://thisisgreat.com") }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  describe 'not authenticated' do
    before { patch("/v3/user/#{user.id}/beta_feature/#{beta_feature.id}") }
    include_examples 'not authenticated'
  end

  describe 'authenticated, missing user' do
    before { patch("/v3/user/999999999/beta_feature/#{beta_feature.id}", {}, auth_headers) }
    include_examples 'missing user'
  end

  describe 'authenticated, existing user, missing beta feature' do
    before { patch("/v3/user/#{user.id}/beta_feature/foo", {}, auth_headers) }
    include_examples 'missing beta_feature'
  end

  describe 'authenticated, existing user, existing user beta feature' do
    let(:params) do
      {
        'beta_feature.id' => beta_feature.id,
        'beta_feature.enabled' => true
      }
    end
    let(:user_beta_feature){ Travis::API::V3::Models::UserBetaFeature.create(user: user, beta_feature: beta_feature, enabled:false) }

    before do
      user_beta_feature
      patch("/v3/user/#{user.id}/beta_feature/#{beta_feature.id}", JSON.generate(params), auth_headers.merge(json_headers))
    end

    example { expect(last_response.status).to eq 200 }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'beta_feature',
        '@representation' => 'standard',
        'id' => user_beta_feature.id,
        'name' => beta_feature.name,
        'description' => beta_feature.description,
        'feedback_url' => beta_feature.feedback_url,
        'enabled' => true
      )
    end
    example 'persists changes' do
      expect(user.reload.beta_features.first.name).to eq 'FOO2'
    end
  end

  describe 'authenticated, existing user, existing beta feature, new user beta feature' do
    let(:params) do
      {
        'beta_feature.id' => beta_feature.id,
        'beta_feature.enabled' => true
      }
    end

    before do
      patch("/v3/user/#{user.id}/beta_feature/#{beta_feature.id}", JSON.generate(params), auth_headers.merge(json_headers))
    end

    example { expect(last_response.status).to eq 200 }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'beta_feature',
        '@representation' => 'standard',
        'id' => user.reload.user_beta_features.last.id,
        'name' => beta_feature.name,
        'description' => beta_feature.description,
        'feedback_url' => beta_feature.feedback_url,
        'enabled' => true
      )
    end
    example 'persists changes' do
      expect(user.reload.beta_features.first.name).to eq 'FOO2'
    end
  end
end
