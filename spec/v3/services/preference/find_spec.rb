describe Travis::API::V3::Services::Preference::Find, set_app: true do
  let(:user) { Travis::API::V3::Models::User.create!(name: 'svenfuchs') }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  describe 'not authenticated' do
    before { get("/v3/preference/build_emails") }
    include_examples 'not authenticated'
  end

  describe 'authenticated, pref missing, return default' do
    before { get("/v3/preference/build_emails", {}, auth_headers) }

    example { expect(last_response.status).to eq(200) }
    example do
      expect(parsed_body).to eql_json(
        "@type" => "preference",
        "@href" => "/v3/preference/build_emails",
        "@representation" => "standard",
        "name" => "build_emails",
        "value" => true
      )
    end
  end

  describe 'authenticated, pref found' do
    before do
      user.preferences.update(:build_emails, false)
      get("/v3/preference/build_emails", {}, auth_headers)
    end

    example { expect(last_response.status).to eq(200) }
    example do
      expect(parsed_body).to eql_json(
        "@type" => "preference",
        "@href" => "/v3/preference/build_emails",
        "@representation" => "standard",
        "name" => "build_emails",
        "value" => false
      )
    end
  end
end
