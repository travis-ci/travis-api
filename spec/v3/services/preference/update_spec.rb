describe Travis::API::V3::Services::Preference::Update, set_app: true do
  let(:github_oauth_token) { 'bar' }
  let(:user) { Travis::API::V3::Models::User.create!(name: 'svenfuchs', github_oauth_token: github_oauth_token) }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}", 'CONTENT_TYPE' => 'application/json' } }
  let(:params) { JSON.dump('preference.value' => false) }

  describe 'not authenticated' do
    before do
      patch("/v3/preference/build_emails")
    end
    include_examples 'not authenticated'
  end

  describe 'authenticated' do
    before do
      patch("/v3/preference/build_emails", params, headers)
    end
    example { expect(last_response.status).to eq 200 }
    example do
      expect(parsed_body).to eql_json(
        "@type" => "preference",
        "@href" => "/v3/preference/build_emails",
        "@representation" => "standard",
        "name" => "build_emails",
        "value" => false
      )
    end
    example 'PENDING: Return validation error'
    example do
      expect(user.github_oauth_token).to eq github_oauth_token
    end
  end
end
