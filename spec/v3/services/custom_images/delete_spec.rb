describe Travis::API::V3::Services::CustomImages::Delete, set_app: true do
  let(:user)    { FactoryBot.create(:user) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  let(:parsed_body) { JSON.load(body) }
  let(:url) { 'https://artifact-manager.travis-ci.com' }
  let(:auth_key) { 'super_secret' }

  before do
    Travis.config.artifact_manager.url = url
    Travis.config.artifact_manager.auth_key = auth_key
    Travis.config.host = 'travis-ci.com'
  end

  context 'authenticated' do
    describe "deleting custom images by id list" do
      before do
        stub_request(:delete, %r{#{Travis.config.artifact_manager.url}/image/user/#{user.id}/\d+})
          .to_return(status: 204, headers: { 'Content-Type' => 'application/json' })
      end

      it 'makes call to artifact manager' do
        delete("/v3/owner/#{user.login}/custom_images", { image_ids: [1, 2, 3] }, headers)

        expect(last_response.status).to eq(204)
        expect(last_response.body).to be_empty
      end
    end

    describe "deleting custom images with no permissions" do
      let(:organization) { FactoryBot.create(:org) }

      before { stub_request(:get, %r((.+)/roles/org/(.+))).to_return(status: 200, body: JSON.generate({ 'roles' => [] })) }

      it 'returns an error' do
        delete("/v3/owner/GitHub/#{organization.name}/custom_images", { image_ids: [1, 2, 3] }, headers)

        expect(last_response.status).to eq(403)
        expect(parsed_body).to include(
          'error_type' => 'insufficient_access'
        )
      end
    end
  end
end
