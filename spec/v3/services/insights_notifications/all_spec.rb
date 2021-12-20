describe Travis::API::V3::Services::InsightsNotifications::All, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/insights_notifications')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:page) { '1' }
    let(:expected_json) do
      {
        "@type" => "notifications",
        "@href" => "/v3/insights_notifications",
        "@representation" => "standard",
        "@pagination" => {
          "limit" => 25,
          "offset" => 0,
          "count" => 2,
          "is_first" => true,
          "is_last" => true,
          "next" => nil,
          "prev" => nil,
          "first" => {
            "@href" => "/v3/insights_notifications",
            "offset" => 0,
            "limit" => 25
          },
          "last" => {
            "@href" => "/v3/insights_notifications",
            "offset" => 0,
            "limit" => 25
          }
        },
        "notifications" => [
          {
            "@type" => "insights_notification", 
            "@representation" => "standard",
            "id" => 8,
            "type" => nil,
            "active" => true,
            "weight" => nil,
            "message" => "This is a test notification",
            "plugin_name" => "Travis Insights",
            "plugin_type" => "Travis Insights",
            "plugin_category" => "Monitoring",
            "probe_severity" => "high",
            "description" => "This is a test notification",
            "description_link" => nil
          },
          {
            "@type" => "insights_notification",
            "@representation" => "standard",
            "id" => 7,
            "type" => nil,
            "active" => true,
            "weight" => nil,
            "message" => "This is a test notification",
            "plugin_name" => "Travis Insights",
            "plugin_type" => "Travis Insights",
            "plugin_category" => "Monitoring",
            "probe_severity" => "high", 
            "description" => "This is a test notification",
            "description_link" => nil
          }
        ]
      }
    end

    before do
      stub_insights_request(:get, '/user_notifications', query: "page=#{page}", auth_key: insights_auth_key, user_id: user.id)
        .to_return(body: JSON.dump(insights_notifications_response))
    end

    it 'responds with list of plugins' do
      get('/v3/insights_notifications', {}, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
