describe Travis::API::V3::Services::AccessToken::RegenerateToken, set_app: true do
  let(:user)    { FactoryBot.create(:user) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 0) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  let(:parsed_body) { JSON.load(body) }

  describe "regenerating the API access token" do
    before     { patch('/v3/access_token', {}, headers) }
    example    { expect(last_response.status).to eq 200 }
    example    { expect(Travis.redis.exists("t:#{token}")).to be_falsey }
    example    { expect(Travis.redis.exists("t:#{parsed_body['token']}")).to be_truthy }
  end
end
