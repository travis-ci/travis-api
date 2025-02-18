describe Travis::API::V3::Services::AccountEnvVar::Delete, set_app: true do
  let(:user)    { FactoryBot.create(:user) }
  let(:account_env_var) { Travis::API::V3::Models::AccountEnvVar.new.save_account_env_var!('User', user.id, 'TEST_VAR', 'VAL', true) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  let(:parsed_body) { JSON.load(body) }

  describe "deleting account env var by id" do
    before     { delete("/v3/account_env_var/#{account_env_var.id}", {}, headers) }
    example    { expect(last_response.status).to eq 204 }
    example    { expect(Travis::API::V3::Models::AccountEnvVar.where(id: account_env_var.id)).to be_empty }
    example    { expect(parsed_body).to be_nil }
  end
end
