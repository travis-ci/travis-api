require 'spec_helper'

describe Travis::API::V3::Services::SslKey::Create, set_app: true do
  let(:repo) do
    Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create.tap do |repo|
      repo.create_key.tap { |key| key.generate_keys!; key.save! }
    end
  end
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:other_token) { Travis::Api::App::AccessToken.create(user: other_user, app_id: 2) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  let(:authorization) { { 'permissions' => ['repository_settings_read', 'repository_settings_create'] } }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe 'not authenticated' do
    before { post("/v3/repo/#{repo.id}/key_pair/generated") }
    include_examples 'not authenticated'
  end

  context 'authenticated as user with wrong permissions' do
    describe 'not allowed' do
      before do
        Travis::API::V3::Models::Permission.create(repository: repo, user: other_user, pull: true)
        post("/v3/repo/#{repo.id}/key_pair/generated", {}, 'HTTP_AUTHORIZATION' => "token #{other_token}")

      end

      let(:authorization) { { 'permissions' => ['repository_settings_read'] } }
      include_examples 'insufficient access to repo', 'create_key_pair'
    end
  end

  context 'authenticated as user with correct permissions' do
    describe 'missing repo' do
      before { post("/v3/repo/999999999/key_pair/generated", {}, auth_headers) }
      include_examples 'missing repo'
    end

    describe 'existing repo, creates key when none exists' do
      before do
        Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
        repo.key.destroy
        post("/v3/repo/#{repo.id}/key_pair/generated", {}, auth_headers)
      end

      example { expect(last_response.status).to eq 201 }
      example do
        expect(JSON.parse(last_response.body)).to include *%w{@type @href @representation description public_key fingerprint}
      end
    end

    describe 'existing repo, regenerates key when one exists' do
      let!(:key) { repo.key }

      before do
        Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
        post("/v3/repo/#{repo.id}/key_pair/generated", {}, auth_headers)
      end

      example { expect(last_response.status).to eq 201 }
      example do
        result = JSON.parse(last_response.body)
        expect(result).to include *%w{@type @href @representation description public_key fingerprint}
        expect(result['fingerprint']).to eq(key.reload.fingerprint)
      end
    end
  end

  context do
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }

    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before { post("/v3/repo/#{repo.id}/key_pair/generated", {}, auth_headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before { repo.update(migration_status: "migrated") }
      before { post("/v3/repo/#{repo.id}/key_pair/generated", {}, auth_headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
