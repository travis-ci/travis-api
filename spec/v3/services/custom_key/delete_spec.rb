describe Travis::API::V3::Services::CustomKey::Delete, set_app: true do
  let(:user)    { FactoryBot.create(:user) }
  let(:private_key) { OpenSSL::PKey::RSA.new(TEST_PRIVATE_KEY).to_pem }
  let(:custom_key) { Travis::API::V3::Models::CustomKey.new.save_key!('User', user.id, 'TEST_KEY', '', private_key, user.id) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  let(:parsed_body) { JSON.load(body) }

  describe "deleting a custom key by id" do
    before     { delete("/v3/custom_key/#{custom_key.id}", {}, headers) }
    example    { expect(last_response.status).to eq 204 }
    example    { expect(Travis::API::V3::Models::CustomKey.where(id: custom_key.id)).to be_empty }
    example    { expect(parsed_body).to be_nil }
  end
end
