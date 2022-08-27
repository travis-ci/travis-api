describe Travis::API::V3::Services::Preferences::ForUser, set_app: true do
  let(:user) { Travis::API::V3::Models::User.create!(name: 'svenfuchs') }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  describe 'not authenticated' do
    before { get("/v3/preferences") }
    include_examples 'not authenticated'
  end

  describe 'authenticated, user has no prefs, return defaults' do
    before { get("/v3/preferences", {}, auth_headers) }

    example { expect(last_response.status).to eq(200) }

    example do
      expect(parsed_body).to eql_json(
        "@type" => "preferences",
        "@href" => "/v3/preferences",
        "@representation" => "standard",
        "preferences" => [
          {
            "@type" => "preference",
            "@href" => "/v3/preference/build_emails",
            "@representation" => "standard",
            "name" => "build_emails",
            "value" => true
          }, {
            "@type" => "preference",
            "@href" => "/v3/preference/consume_oss_credits",
            "@representation" => "standard",
            "name" => "consume_oss_credits",
            "value" => true
          }, {
            "@type" => "preference",
            "@href" => "/v3/preference/private_insights_visibility",
            "@representation" => "standard",
            "name" => "private_insights_visibility",
            "value" => "private"
          }, {
            "@type" => "preference",
            "@href" => "/v3/preference/insights_scan_notifications",
            "@representation" => "standard",
            "name" => "insights_scan_notifications",
            "value" => true
          }, {
            "@type" => "preference",
            "@href" => "/v3/preference/insights_time_zone",
            "@representation" => "standard",
            "name" => "insights_time_zone",
            "value" => ""
          }, {
            "@type" => "preference",
            "@href" => "/v3/preference/insights_date_format",
            "@representation" => "standard",
            "name" => "insights_date_format",
            "value" => "DD/MM/YYYY"
          }, {
            "@type" => "preference",
            "@href" => "/v3/preference/insights_time_format",
            "@representation" => "standard",
            "name" => "insights_time_format",
            "value" => "HH:mm:ss"
          }
        ]
      )
    end
  end

  describe 'authenticated, user has prefs' do
    before do
      user.preferences.update(:build_emails, false)
      user.preferences.update(:consume_oss_credits, false)
      user.preferences.update(:private_insights_visibility, 'public')
      user.preferences.update(:insights_scan_notifications, false)
      user.preferences.update(:insights_time_zone, '(GMT-12:00) Etc/GMT+12')
      user.preferences.update(:insights_date_format, 'YYYY/MM/DD')
      user.preferences.update(:insights_time_format, 'h:mm:ss A')
      get("/v3/preferences", {}, auth_headers)
    end

    example { expect(last_response.status).to eq(200) }

    example do
      expect(parsed_body).to eql_json(
        "@type" => "preferences",
        "@href" => "/v3/preferences",
        "@representation" => "standard",
        "preferences" => [
          {
            "@type" => "preference",
            "@href" => "/v3/preference/build_emails",
            "@representation" => "standard",
            "name" => "build_emails",
            "value" => false
          }, {
            "@type" => "preference",
            "@href" => "/v3/preference/consume_oss_credits",
            "@representation" => "standard",
            "name" => "consume_oss_credits",
            "value" => false
          }, {
            "@type" => "preference",
            "@href" => "/v3/preference/private_insights_visibility",
            "@representation" => "standard",
            "name" => "private_insights_visibility",
            "value" => "public"
          }, {
            "@type" => "preference",
            "@href" => "/v3/preference/insights_scan_notifications",
            "@representation" => "standard",
            "name" => "insights_scan_notifications",
            "value" => false
          }, {
            "@type" => "preference",
            "@href" => "/v3/preference/insights_time_zone",
            "@representation" => "standard",
            "name" => "insights_time_zone",
            "value" => "(GMT-12:00) Etc/GMT+12"
          }, {
            "@type" => "preference",
            "@href" => "/v3/preference/insights_date_format",
            "@representation" => "standard",
            "name" => "insights_date_format",
            "value" => "YYYY/MM/DD"
          }, {
            "@type" => "preference",
            "@href" => "/v3/preference/insights_time_format",
            "@representation" => "standard",
            "name" => "insights_time_format",
            "value" => "h:mm:ss A"
          }
        ]
      )
    end
  end
end
