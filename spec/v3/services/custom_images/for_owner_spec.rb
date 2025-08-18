require 'spec_helper'

RSpec.describe Travis::API::V3::Services::CustomImages::ForOwner, set_app: true do
  let(:json_headers) { { 'HTTP_ACCEPT' => 'application/json' } }
  let(:authorization) { { 'permissions' => [ 'repository_state_update', 'repository_build_create' ] } }

  before do
    Travis.config.host = 'travis-ci.com'
    stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization))
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user, name: 'Joe', login: 'joe') }
    let(:user_token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let!(:repository) { FactoryBot.create(:repository, owner: user) }
    let!(:custom_image) { FactoryBot.create(:custom_image, owner: user) }
    let!(:custom_image_log) { FactoryBot.create(:custom_image_log, custom_image: custom_image, sender_id: user.id) }

    context 'when user has custom images' do
      subject { get("/v3/owner/#{user.login}/custom_images", {}, json_headers.merge('HTTP_AUTHORIZATION' => "token #{user_token}")) }

      it 'returns custom images' do
        subject
        expect(last_response).to be_ok
        custom_image_response = JSON.parse(last_response.body)['custom_images'].first
        expect(custom_image_response).to include(
          'id' => custom_image.id,
          'name' => custom_image.name,
          'size_bytes' => custom_image.size_bytes
        )
        expect(custom_image_response['created_by']['avatar_url']).to be_present
      end

      context 'when user email is blank' do
        before { user.update(email: nil) }

        it 'skips avatar_url' do
          subject
          expect(last_response).to be_ok
          expect(JSON.parse(last_response.body)['custom_images'].first['created_by']).not_to have_key('avatar_url')
        end
      end
    end

    context 'when user has no build create permission' do
      let(:other_user) { FactoryBot.create(:user, name: 'Jane', login: 'jane') }
      let(:other_user_token) { Travis::Api::App::AccessToken.create(user: other_user, app_id: 1) }
      let!(:repository) { FactoryBot.create(:repository, owner: other_user) }
      let(:authorization) { { 'permissions' => [ 'repository_state_update' ] } }

      it 'returns an empty list' do
        get("/v3/owner/#{user.login}/custom_images", {}, json_headers.merge('HTTP_AUTHORIZATION' => "token #{other_user_token}"))

        expect(JSON.parse(last_response.body)).to include(
          'error_type' => 'insufficient_access'
        )
      end
    end
  end
end
