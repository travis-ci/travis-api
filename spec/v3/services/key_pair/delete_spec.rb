require 'spec_helper'
require 'openssl'

describe Travis::API::V3::Services::KeyPair::Delete, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:key) { OpenSSL::PKey::RSA.generate(4096) }
  let(:key_pair) { { description: 'foo key pair', value: Travis::Settings::EncryptedValue.new(key.to_pem), repository_id: repo.id } }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  shared_examples 'paid' do
    describe 'not authenticated' do
      before { delete("/v3/repo/#{repo.id}/key_pair") }
      include_examples 'not authenticated'
    end

    context 'authenticated' do
      describe 'missing repo' do
        before { delete('/v3/repo/999999999/key_pair', {}, auth_headers) }
        include_examples 'missing repo'
      end

      context 'existing repo' do
        describe 'authenticated user with wrong permissions' do

          let(:authorization) { { 'permissions' => [] } }
          before do
            Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
            repo.update(settings: { ssh_key: key_pair, foo: 'bar' })
            delete("/v3/repo/#{repo.id}/key_pair", {}, { 'HTTP_AUTHORIZATION' => "token #{token}" })
          end
          include_examples 'insufficient access to repo', 'delete_key_pair'
        end

        context 'authenticated user with correct permissions' do
          before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, push: true) }

          describe 'existing repo, no key pair' do
            before { delete("/v3/repo/#{repo.id}/key_pair", {}, auth_headers) }

            example { expect(last_response.status).to eq 404 }
            example do
              expect(JSON.parse(last_response.body)).to eq(
                '@type' => 'error',
                'error_message' => 'key_pair not found (or insufficient access)',
                'error_type' => 'not_found',
                'resource_type' => 'key_pair'
              )
            end
          end

          describe 'existing repo, deletes key pair' do
            before do
              repo.update(settings: { ssh_key: key_pair, foo: 'bar' })
              delete("/v3/repo/#{repo.id}/key_pair", {}, auth_headers)
            end

            example { expect(last_response.status).to eq 204 }
            example do
              expect(last_response.body).to be_empty
            end
            example 'persists changes' do
              expect(repo.reload.settings).to eq("foo"=>"bar")
            end
          end
        end
      end
    end
  end

  context 'enterprise' do
    around(:each) do |example|
      Travis.config.enterprise = true
      example.run
      Travis.config.enterprise = nil
    end

    include_examples 'paid'
  end

  context 'private repo' do
    before { repo.update(private: true) }

    include_examples 'paid'
  end

  context 'non-paid' do
    before { delete("/v3/repo/#{repo.id}/key_pair", {}, auth_headers) }

    include_examples 'paid feature error'
  end

  context do
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true, pull: true) }
    before { repo.update(private: true) }

    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before { delete("/v3/repo/#{repo.id}/key_pair", {}, auth_headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before { repo.update(migration_status: "migrated") }
      before { delete("/v3/repo/#{repo.id}/key_pair", {}, auth_headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
