describe Travis::API::V3::Services::Gdpr::Export, set_app: true, gdpr_spec_helper: true do
  let(:gdpr_url) { 'http://gdpr.travis-ci.dev' }
  let(:gdpr_auth_token) { 'secret' }

  before do
    Travis.config.gdpr.endpoint = gdpr_url
    Travis.config.gdpr.auth_token = gdpr_auth_token
  end

  context 'unauthenticated' do
    it 'responds 403' do
      post('/v3/gdpr/export')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}

    let!(:request) do
      stub_gdpr_request(:post, "/user/#{user.id}/export", user_id: user.id).to_return(status: 204)
    end

    it 'requests the export from the GDPR service' do
      post('/v3/gdpr/export', {}, headers)

      expect(last_response.status).to eq(204)
      expect(request).to have_been_made.once
    end
  end
end
