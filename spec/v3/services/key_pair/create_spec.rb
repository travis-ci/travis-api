require 'spec_helper'
require 'openssl'

describe Travis::API::V3::Services::KeyPair::Create, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  shared_examples 'paid' do
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
        describe 'wrong permissions' do
          before do
            Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
            post("/v3/repo/#{repo.id}/key_pair", {}, { 'HTTP_AUTHORIZATION' => "token #{token}" })
          end
          include_examples 'insufficient access to repo', 'create_key_pair'
        end

        context 'correct permissions' do
          before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true,  push: true) }

          describe 'key pair already exists' do
            let(:key) { OpenSSL::PKey::RSA.generate(2048) }
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
            include_examples 'wrong params'
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
            let(:key) { OpenSSL::PKey::RSA.generate(2048) }
            let(:fingerprint) { Travis::API::V3::Models::Fingerprint.calculate(key.to_pem) }
            let(:params) do
              {
                'key_pair.value' => key.to_pem,
                'key_pair.description' => 'foo key pair'
              }
            end

            before do
              post("/v3/repo/#{repo.id}/key_pair", JSON.generate(params), auth_headers.merge(json_headers))
            end

            example { expect(last_response.status).to eq 201 }
            example do
              expect(JSON.parse(last_response.body)).to eq(
                '@href' => "/v3/repo/#{repo.id}/key_pair",
                '@representation' => 'standard',
                '@permissions' => { 'read' => true, 'write' => true },
                '@type' => 'key_pair',
                'description' => 'foo key pair',
                'fingerprint' =>  fingerprint,
                'public_key' => key.public_key.to_s
              )
            end
            example 'persists changes' do
              expect(repo.reload.settings['ssh_key']['description']).to eq 'foo key pair'
            end
            example 'persists repository id' do
              expect(repo.reload.settings['ssh_key']['repository_id']).to eq repo.id
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
    before { repo.update_attributes(private: true) }

    include_examples 'paid'
  end

  context 'non-paid' do
    before { post("/v3/repo/#{repo.id}/key_pair", {}, auth_headers.merge(json_headers)) }

    include_examples 'paid feature error'
  end
end
