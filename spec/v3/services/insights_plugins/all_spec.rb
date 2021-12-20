describe Travis::API::V3::Services::InsightsPlugins::All, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/insights_plugins')

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
        "@type" => "plugins",
        "@href" => "/v3/insights_plugins",
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
            "@href" => "/v3/insights_plugins",
            "offset" => 0,
            "limit" => 25
          },
          "last" => {
            "@href" => "/v3/insights_plugins",
            "offset" => 0,
            "limit" => 25
          }
        },
        "plugins" => [
          {
            "@type" => "insights_plugin",
            "@representation" => "standard",
            "id" => 5,
            "name" => "KubePlugin",
            "public_id" => "TID6CD47CD6E26",
            "plugin_type" => "Kubernetes Cluster",
            "plugin_category" => "Monitoring",
            "last_scan_end" => nil,
            "scan_status" => "In Progress",
            "plugin_status" => "Active",
            "active" => true
          }, 
          {
            "@type" => "insights_plugin",
            "@representation" => "standard",
            "id" => 3,
            "name" => "KubePlugin2",
            "public_id" => "TI74D0AACAC0BD",
            "plugin_type" => "Kubernetes Cluster",
            "plugin_category" => "Monitoring",
            "last_scan_end" => "2021-12-01 10:44:32",
            "scan_status" => "Success",
            "plugin_status" => "Active",
            "active" => true
          }
        ]
      }
    end

    before do
      stub_insights_request(:get, '/user_plugins', query: "page=#{page}", auth_key: insights_auth_key, user_id: user.id)
        .to_return(body: JSON.dump(insights_plugins_response))
    end

    it 'responds with list of plugins' do
      get('/v3/insights_plugins', {}, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
