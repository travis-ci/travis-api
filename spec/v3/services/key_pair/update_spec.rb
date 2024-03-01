require 'spec_helper'

describe Travis::API::V3::Services::KeyPair::Update, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }
  shared_examples 'paid' do
    describe 'not authenticated' do
      before { patch("/v3/repo/#{repo.id}/key_pair") }
      include_examples 'not authenticated'
    end

    context 'authenticated' do
      describe 'missing repo' do
        before { patch('/v3/repo/999999999/key_pair', {}, auth_headers) }
        include_examples 'missing repo'
      end

      context 'existing repo' do
        describe 'correct user, wrong permissions' do
          let(:key) { OpenSSL::PKey::RSA.generate(2048) }

          let(:authorization) { { 'permissions' => ['repository_settings_read'] } }
          before do
            Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
            repo.update_attribute(:settings, JSON.generate(ssh_key: { description: 'foo', value: Travis::Settings::EncryptedValue.new(key.to_pem), repository_id: repo.id }))
            patch("/v3/repo/#{repo.id}/key_pair", JSON.generate({}), auth_headers.merge(json_headers))
          end

          example { expect(last_response.status).to eq 403 }
          example do
            expect(JSON.parse(last_response.body)).to eq(
              '@type' => 'error',
              'error_type' => 'insufficient_access',
              'error_message' => 'operation requires write access to key_pair',
              'permission' => 'write',
              'resource_type' => 'key_pair',
              'key_pair' => {
                '@href' => "/v3/repo/#{repo.id}/key_pair",
                '@representation' => 'minimal',
                '@type' => 'key_pair',
                'description' => 'foo',
                'fingerprint' => Travis::API::V3::Models::Fingerprint.calculate(key.to_pem),
                'public_key' => key.public_key.to_s
              }
            )
          end
        end

        context 'correct user, correct permissions' do
          let(:key) { OpenSSL::PKey::RSA.generate(2048) }

          before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, push: true) }

          describe 'missing key pair' do
            before { patch("/v3/repo/#{repo.id}/key_pair", {}, auth_headers.merge(json_headers)) }

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

          describe 'wrong params have no effect but return warning' do
            let(:params) do
              {
                'key_pair.xyz' => 'this does nothing'
              }
            end

            before do
              repo.update_attribute(:settings, JSON.generate(ssh_key: { description: 'foo', value: Travis::Settings::EncryptedValue.new(key.to_pem), repository_id: repo.id }))
              patch("/v3/repo/#{repo.id}/key_pair", JSON.generate(params), auth_headers.merge(json_headers))
            end

            example { expect(last_response.status).to eq 200 }
            example do
              expect(JSON.parse(last_response.body)).to eq(
                '@href' => "/v3/repo/#{repo.id}/key_pair",
                '@representation' => 'standard',
                '@type' => 'key_pair',
                '@permissions' => { 'read' => true, 'write' => true },
                '@warnings' => [
                  {
                    '@type' => 'warning',
                    'message' => 'query parameter key_pair.xyz not safelisted, ignored',
                    'warning_type' => 'ignored_parameter',
                    'parameter' => 'key_pair.xyz'
                  }
                ],
                'description' => 'foo',
                'fingerprint' => Travis::API::V3::Models::Fingerprint.calculate(key.to_pem),
                'public_key' => key.public_key.to_s
              )
            end
          end

          describe 'invalid private key' do
            let(:params) do
              {
                'key_pair.description' => 'new description',
                'key_pair.value' => 'not a real key'
              }
            end

            before do
              repo.update_attribute(:settings, JSON.generate(ssh_key: { description: 'foo', value: Travis::Settings::EncryptedValue.new(key.to_pem), repository_id: repo.id }))
              patch("/v3/repo/#{repo.id}/key_pair", JSON.generate(params), auth_headers.merge(json_headers))
            end

            example { expect(last_response.status).to eq 422 }
            example do
              expect(JSON.parse(last_response.body)).to eq(
                '@type' => 'error',
                'error_message' => 'request unable to be processed due to semantic errors',
                'error_type' => 'unprocessable_entity'
              )
            end
          end

          describe 'updates key pair' do
            let(:new_key) { OpenSSL::PKey::RSA.generate(2048) }
            let(:params) do
              {
                'key_pair.description' => 'new description',
                'key_pair.value' => new_key.to_pem
              }
            end

            before do
              repo.update_attribute(:settings, JSON.generate(ssh_key: { description: 'foo', value: Travis::Settings::EncryptedValue.new(key.to_pem), repository_id: repo.id }))
              patch("/v3/repo/#{repo.id}/key_pair", JSON.generate(params), auth_headers.merge(json_headers))
            end

            example { expect(last_response.status).to eq 200 }
            example do
              expect(JSON.parse(last_response.body)).to eq(
                '@href' => "/v3/repo/#{repo.id}/key_pair",
                '@representation' => 'standard',
                '@type' => 'key_pair',
                '@permissions' => { 'read' => true, 'write' => true },
                'description' => 'new description',
                'fingerprint' => Travis::API::V3::Models::Fingerprint.calculate(new_key.to_pem),
                'public_key' => new_key.public_key.to_s
              )
            end
            example 'persists changes' do
              expect(repo.reload.settings['ssh_key']['description']).to eq 'new description'
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
    before { patch("/v3/repo/#{repo.id}/key_pair", {}, auth_headers.merge(json_headers)) }

    include_examples 'paid feature error'
  end

  context do
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true, pull: true) }
    before { repo.update(private: true) }

    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before { patch("/v3/repo/#{repo.id}/key_pair", JSON.generate({}), auth_headers.merge(json_headers)) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before { repo.update(migration_status: "migrated") }
      before { patch("/v3/repo/#{repo.id}/key_pair", JSON.generate({}), auth_headers.merge(json_headers)) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
