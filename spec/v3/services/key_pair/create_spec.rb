require 'spec_helper'
require 'openssl'

describe Travis::API::V3::Services::KeyPair::Create, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:other_user) { FactoryGirl.create(:user) }
  let(:other_token) { Travis::Api::App::AccessToken.create(user: other_user, app_id: 2) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  describe 'not authenticated' do
    before { post("/v3/repo/#{repo.id}/key_pair") }
    include_examples 'not authenticated'
  end

  context 'authenticated' do
    describe 'missing repo' do
      before { post('/v3/repo/999999999/key_pair', {}, auth_headers) }
      include_examples 'missing repo'
    end

    context 'existing repo' do
      describe 'authenticated as wrong user' do
        before { post("/v3/repo/#{repo.id}/key_pair", {}, { 'HTTP_AUTHORIZATION' => "token #{other_token}" }) }

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

        describe 'key pair already exists' do
          let(:key) { OpenSSL::PKey::RSA.generate(4096) }
          let(:params) do
            {
              'key_pair.description' => 'foo',
              'key_pair.value' => key.to_pem
            }
          end

          before do
            repo.update_attribute(:settings, JSON.generate(ssh_key: { description: 'foo', value: Travis::Settings::EncryptedValue.new(key.to_pem) }))
            post("/v3/repo/#{repo.id}/key_pair", JSON.generate(params), auth_headers.merge(json_headers))
          end

          example { expect(last_response.status).to eq 409 }
          example do
            expect(JSON.parse(last_response.body)).to eq(
              '@type' => 'error',
              'error_message' => 'resource already exists',
              'error_type' => 'duplicate_resource'
            )
          end
        end

        describe 'wrong params' do
          let(:params) do
            {
              'key_pair.description' => 'hello'
            }
          end

          before { post("/v3/repo/#{repo.id}/key_pair", JSON.generate(params), auth_headers.merge(json_headers)) }

          example { expect(last_response.status).to eq 400 }
          example do
            expect(JSON.parse(last_response.body)).to eq(
              '@type' => 'error',
              'error_message' => 'wrong parameters',
              'error_type' => 'wrong_params'
            )
          end
        end

        describe 'value is not valid private key' do
          let(:params) do
            {
              'key_pair.value' => 'not a proper private key'
            }
          end

          before { post("/v3/repo/#{repo.id}/key_pair", JSON.generate(params), auth_headers.merge(json_headers)) }

          example { expect(last_response.status).to eq 422 }
          example do
            expect(JSON.parse(last_response.body)).to eq(
              '@type' => 'error',
              'error_message' => 'request unable to be processed due to semantic errors',
              'error_type' => 'unprocessable_entity'
            )
          end
        end

        describe 'creates key pair' do
          let(:key) { OpenSSL::PKey::RSA.generate(4096) }
          let(:fingerprint) { Travis::API::V3::Models::Fingerprint.calculate(key.to_pem) }
          let(:params) do
            {
              'key_pair.value' => key.to_pem,
              'key_pair.description' => 'foo key pair'
            }
          end

          before { post("/v3/repo/#{repo.id}/key_pair", JSON.generate(params), auth_headers.merge(json_headers)) }

          example { expect(last_response.status).to eq 201 }
          example do
            expect(JSON.parse(last_response.body)).to eq(
              '@href' => "/v3/repo/#{repo.id}/key_pair",
              '@representation' => 'standard',
              '@type' => 'key_pair',
              'description' => 'foo key pair',
              'fingerprint' =>  fingerprint
            )
          end
          example 'persists changes' do
            expect(repo.reload.settings['ssh_key']['description']).to eq 'foo key pair'
          end
        end
      end
    end
  end
end
