describe Travis::API::V3::Services::CustomKeys::Create, set_app: true do
  let(:private_key) { OpenSSL::PKey::RSA.new(TEST_PRIVATE_KEY).to_pem }
  let(:user)    { FactoryBot.create(:user) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}", "Content-Type" => "application/json" }}
  let(:options) do
    {
      'owner_id' => user.id,
      'owner_type' => 'User',
      'added_by' => user.id,
      'name' => 'TEST_KEY',
      'private_key' => private_key,
      'description' => ''
    }
  end
  let(:parsed_body) { JSON.load(body) }

  describe "try creating a custom key without login" do
    before     { post('/v3/custom_keys', options) }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    })}
  end

  describe "creating custom key" do
    before  { post('/v3/custom_keys', options, headers) }
    example { expect(parsed_body.except("id")).to eql_json({
      "@type" => "custom_key",
      "@representation" => "standard",
      "name" => "TEST_KEY",
      "description" => "",
      "public_key" =>
       "-----BEGIN PUBLIC KEY-----\n" +
       "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6Dm1n+fc0ILeLWeiwqsW\n" +
       "s1MZaGAfccrmpvuxfcE9UaJp2POy079g+mdiBgtWfnQlU84YX31rU2x9GJwnb8G6\n" +
       "UcvkEjqczOgHHmELtaNmrRH1g8qOfJpzXB8XiNib1L3TDs7qYMKLDCbl2bWrcO7D\n" +
       "ol9bSqIeb7f9rzkCd4tuXObL3pMD/VIW5uzeVqLBAc0Er+qw6U7clnMnHHMekXt4\n" +
       "JSRfauSCxktR2FzigoQbJc8t4iWOrmNi5Q84VkXB3X7PO/eajUw+RJOl6FnPN1Zh\n" +
       "08ceqcqmSMM4RzeVQaczXg7P92P4mRF41R97jIJyzUGwheb2Z4Q2rltck4V7R5Bv\n" +
       "MwIDAQAB\n" +
       "-----END PUBLIC KEY-----\n",
      "fingerprint" => "57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40",
      "added_by_login" => "svenfuchs",
      "created_at" => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
    })}
  end
end
