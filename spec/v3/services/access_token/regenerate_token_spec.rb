describe Travis::API::V3::Services::AccessToken::RegenerateToken, set_app: true do
  let(:user)    { FactoryBot.create(:user) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 0) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}", 'CONTENT_TYPE' => 'application/json' }}
  let(:params)  {{ token: token.token }.to_json }
  let(:parsed_body) { JSON.load(last_response.body) }

  describe "regenerating the API access token" do
    before do
      patch('/v3/access_token', params, headers)
    end

    example { expect(last_response.status).to eq 200 }
    example { expect(Travis.redis.exists?("t:#{token.token}")).to be_falsey }
    example { expect(Travis.redis.exists?("t:#{parsed_body['token']}")).to be_truthy }
  end
end
