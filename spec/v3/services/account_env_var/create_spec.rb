describe Travis::API::V3::Services::CustomKeys::Create, set_app: true do
  let(:user)    { FactoryBot.create(:user) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}", "Content-Type" => "application/json" }}
  let(:options) do
    {
      'owner_id' => user.id,
      'owner_type' => 'User',
      'name' => 'TEST_VAR',
      'value' => 'VAL',
      'public' => true
    }
  end
  let(:parsed_body) { JSON.load(body) }

  describe "try creating a account env var without login" do
    before     { post('/v3/account_env_var', options) }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    })}
  end

  describe "creating account env var" do
    before  { post('/v3/account_env_var', options, headers) }
    example { expect(parsed_body.except("id", "@permissions")).to eql_json({
      "@type" => "account_env_var",
      "@representation" => "standard",
      'owner_id' => user.id,
      'owner_type' => 'User',
      "name" => "TEST_VAR",
      "value" => "VAL",
      "public" => true,
      "created_at" => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
      "updated_at" => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
    })}
  end
end
