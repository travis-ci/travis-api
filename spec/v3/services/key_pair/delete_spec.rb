require 'spec_helper'
require 'openssl'

describe Travis::API::V3::Services::KeyPair::Delete, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:other_user) { FactoryGirl.create(:user) }
  let(:other_token) { Travis::Api::App::AccessToken.create(user: other_user, app_id: 2) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:key) { OpenSSL::PKey::RSA.generate(4096) }
  let(:key_pair) { { description: 'foo key pair', value: key.to_pem, repository_id: repo.id } }

  context 'on .com' do
    around(:each) do |example|
      Travis.config.private_api = true
      example.run
      Travis.config.private_api = nil
    end

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
        describe 'authenticated as wrong user' do
          before { delete("/v3/repo/#{repo.id}/key_pair", {}, { 'HTTP_AUTHORIZATION' => "token #{other_token}" }) }

          example { expect(last_response.status).to eq 403 }
          example do
            expect(JSON.parse(last_response.body)).to eq(
              '@type' => 'error',
              'error_message' => 'operation requires change_key access to repository',
              'error_type' => 'insufficient_access',
              'permission' => 'change_key',
              'repository' => {
                '@type' => 'repository',
                '@href' => "/v3/repo/#{repo.id}",
                '@representation' => 'minimal',
                'id' => repo.id,
                'name' => repo.name,
                'slug' => repo.slug
              },
              'resource_type' => 'repository'
            )
          end
        end

        context 'authenticated as correct user' do
          before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }

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
              repo.update_attributes(settings: JSON.generate(ssh_key: key_pair, foo: 'bar'))
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

  context 'on .org' do
    describe 'service is not available' do
      before { delete("/v3/repo/#{repo.id}/key_pair", {}, auth_headers) }
      include_examples 'com only service'
    end
  end
end
