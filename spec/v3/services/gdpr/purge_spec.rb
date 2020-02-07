describe Travis::API::V3::Services::Gdpr::Purge, set_app: true, gdpr_spec_helper: true do
  let(:gdpr_url) { 'http://gdpr.travis-ci.dev' }
  let(:gdpr_auth_token) { 'secret' }

  before do
    Travis.config.gdpr.endpoint = gdpr_url
    Travis.config.gdpr.auth_token = gdpr_auth_token
  end

  context 'unauthenticated' do
    it 'responds 403' do
      delete('/v3/gdpr/purge')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}

    let!(:request) do
      stub_gdpr_request(:delete, "/user/#{user.id}", user_id: user.id).to_return(status: 204)
    end

    it 'requests the purge from the GDPR service' do
      delete('/v3/gdpr/purge', {}, headers)

      expect(last_response.status).to eq(204)
      expect(request).to have_been_made.once
    end
  end
end
