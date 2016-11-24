require 'spec_helper'

describe Travis::API::V3::Services::SshKey::Create, set_app: true do
  let(:repo) do
    Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create.tap do |repo|
      repo.create_key.tap { |key| key.generate_keys!; key.save! }
    end
  end
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  describe 'not authenticated' do
    before { post("/v3/repo/#{repo.id}/ssh_key") }
    include_examples 'not authenticated'
  end

  describe 'authenticated, missing repo' do
    before { post("/v3/repo/999999999/ssh_key", {}, auth_headers) }
    include_examples 'missing repo'
  end

  describe 'authenticated, existing repo, creates key when none exists' do
    before do
      repo.key.destroy
      post("/v3/repo/#{repo.id}/ssh_key", {}, auth_headers)
    end

    example { expect(last_response.status).to eq 201 }
    example do
      expect(JSON.parse(last_response.body)).to include *%w{@type @href @representation id public_key fingerprint}
    end
  end

  describe 'authenticated, existing repo, regenerates key when one exists' do
    let!(:key) { repo.key }

    before { post("/v3/repo/#{repo.id}/ssh_key", {}, auth_headers) }

    example { expect(last_response.status).to eq 201 }
    example do
      result = JSON.parse(last_response.body)
      expect(result).to include *%w{@type @href @representation id public_key fingerprint}
      expect(result['id']).to eq key.id
      expect(result['fingerprint']).not_to eq(key.fingerprint)
    end
  end
end
