require 'spec_helper'

describe Travis::Api::App::Endpoint::Requests do
  include Travis::Testing::Stubs

  let(:token)    { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  let(:data)     { { request: { repository: { owner_name: 'owner', name: 'name' }, branch: 'branch', config: { env: ['FOO=foo'] } } } }
  let(:headers)  { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json, */*; q=0.01', 'HTTP_AUTHORIZATION' => %(token "#{token.token}") } }
  let(:response) { post('/requests', data, headers) }

  before do
    User.stubs(:find_by_github_id).returns(user)
    User.stubs(:find).returns(user)
  end

  describe 'POST to /' do
    it 'needs to be authenticated' do
      Travis::Api::App::AccessToken.stubs(:find_by_token).returns(nil)
      expect(response.status).to eq 403
    end

    describe 'if the repository does not exist' do
      it 'returns 404' do
        expect(response.status).to eq 404
      end

      it 'includes a notice' do
        expect(response.body).to eq '{"result":"not_found","flash":[{"error":"Repository owner/name not found."}]}'
      end
    end

    describe 'if successful' do
      before do
        Repository.stubs(:by_slug).returns([repo])
        Travis::Sidekiq::BuildRequest.stubs(:perform_async)
        Travis::Features.stubs(:owner_active?).returns(true)
      end

      it 'returns 200' do
        expect(response.status).to eq 200
      end

      it 'includes a notice' do
        expect(response.body).to eq '{"result":"success","flash":[{"notice":"Build request scheduled."}]}'
      end

      it 'schedules the build request' do
        payload = MultiJson.encode(data[:request].merge(user: { id: user.id }))
        Travis::Sidekiq::BuildRequest.expects(:perform_async).with(type: 'api', payload: payload, credentials: {})
        response
      end
    end
  end
end

