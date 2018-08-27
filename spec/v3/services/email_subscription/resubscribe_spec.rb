require 'spec_helper'

describe Travis::API::V3::Services::EmailSubscription::Resubscribe, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  describe 'not authenticated' do
    before { post("/v3/repo/#{repo.id}/email_subscription", {}) }
    include_examples 'not authenticated'
  end

  describe 'authenticated, repo missing' do
    before { post("/v3/repo/999999/email_subscription", {}, auth_headers) }
    include_examples 'missing repo'
  end

  describe 'authenticated, existing repo, user unsubscribed' do
    before do
      delete("/v3/repo/#{repo.id}/email_subscription", {}, auth_headers)
    end

    subject(:response) do
      post("/v3/repo/#{repo.id}/email_subscription", {}, auth_headers)
    end

    it 'responds with 204, empty body' do
      expect(response.status).to eq 204
      expect(response.body).to be_empty
    end

    it 'persists the change' do
      subject

      expect(repo.reload.email_unsubscribes.count).to eq 0
    end

    context 'user was already resubscribed' do
      before do
        post("/v3/repo/#{repo.id}/email_subscription", {}, auth_headers)
      end

      it 'does not error' do
        expect(response.status).to eq 204
      end

      it 'keeps user subscribed' do
        subject

        expect(repo.reload.email_unsubscribes.count).to eq 0
      end
    end
  end
end
