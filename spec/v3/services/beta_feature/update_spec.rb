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

  describe 'authenticated, other user' do
    let(:other_user) { FactoryBot.create(:user, login: 'noone') }
    let(:token) { Travis::Api::App::AccessToken.create(user: other_user, app_id: 1) }
    let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before { patch("/v3/user/#{user.id}/beta_feature/#{beta_feature.id}", {}, auth_headers) }
    include_examples 'missing beta_feature'
  end

  describe 'authenticated, existing user, missing beta feature' do
    before { patch("/v3/user/#{user.id}/beta_feature/foo", {}, auth_headers) }
    example { expect(last_response.status).to eq(404) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'error',
        'error_message' => 'beta_feature not found',
        'error_type' => 'not_found'
      )
    end
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
      Timecop.freeze(Time.now.utc)
      user_beta_feature
      patch("/v3/user/#{user.id}/beta_feature/#{beta_feature.id}", JSON.generate(params), auth_headers.merge(json_headers))
    end
    after do
      Timecop.return
      Timecop.freeze(Time.now.utc)
    end

    example { expect(last_response.status).to eq 200 }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'beta_feature',
        '@representation' => 'standard',
        'id' => beta_feature.id,
        'name' => beta_feature.name,
        'description' => beta_feature.description,
        'feedback_url' => beta_feature.feedback_url,
        'enabled' => true
      )
    end
    example 'persists changes' do
      expect(user.reload.beta_features.first.name).to eq 'FOO2'
    end
    example 'updates last activated at' do
      expect(user.user_beta_features.last.last_activated_at).to be_within(1.second).of Time.now.utc
    end
    example 'sets last deactivated at' do
      Timecop.travel(10) do
        params['beta_feature.enabled'] = false
        patch("/v3/user/#{user.id}/beta_feature/#{beta_feature.id}", JSON.generate(params), auth_headers.merge(json_headers))
        expect(user.user_beta_features.last.last_deactivated_at.utc).to be_within(1.second).of Time.now.utc
      end
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
        'id' => beta_feature.id,
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
