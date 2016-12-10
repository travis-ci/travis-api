require 'spec_helper'

describe Travis::API::V3::Services::BetaFeature::Delete, set_app: true do
  let(:user)  { Travis::API::V3::Models::User.where(login: 'svenfuchs').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:beta_feature) { Travis::API::V3::Models::BetaFeature.create(name: 'FOO', description: "Bar Baz.", feedback_url: "http://thisisgreat.com") }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  describe 'not authenticated' do
    before { delete("/v3/user/#{user.id}/beta_feature/#{beta_feature.id}") }
    include_examples 'not authenticated'
  end

  context 'authenticated, right permissions' do
    describe 'missing user' do
      before { delete("/v3/user/999999999/beta_feature/#{beta_feature.id}", {}, auth_headers) }
      include_examples 'missing user'
    end

    describe 'existing user, missing beta feature' do
      before { delete("/v3/user/#{user.id}/beta_feature/#{beta_feature.id}", {}, auth_headers) }
      include_examples 'missing beta_feature'
    end

    describe 'existing user, existing beta feature' do
      before do
        Travis::API::V3::Models::UserBetaFeature.create(user_id: user.id, beta_feature_id: beta_feature.id)
        delete("/v3/user/#{user.id}/beta_feature/#{beta_feature.id}", {}, auth_headers)
      end

      example 'persists changes' do
        expect(user.reload.user_beta_features.where(beta_feature_id: beta_feature.id).first).to be_nil
      end
    end
  end
end
