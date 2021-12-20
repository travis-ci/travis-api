describe Travis::API::V3::Services::InsightsProbes::All, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/insights_probes')

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
        "@type"=>"tests",
        "@href"=>"/v3/insights_probes",
        "@representation"=>"standard",
        "@pagination"=>{
          "limit"=>25,
          "offset"=>0,
          "count"=>2,
          "is_first"=>true,
          "is_last"=>true,
          "next"=>nil,
          "prev"=>nil,
          "first"=>{
            "@href"=>"/v3/insights_probes",
            "offset"=>0,
            "limit"=>25
          },
          "last"=>{
            "@href"=>"/v3/insights_probes",
            "offset"=>0,
            "limit"=>25
          }
        },
        "tests"=>[
          {
            "@type"=>"insights_probe",
            "@representation"=>"standard",
            "id"=>312,
            "user_id"=>45,
            "user_plugin_id"=>nil,
            "test_template_id"=>312,
            "uuid"=>"d0286ba6-ee08-4d87-9fb5-e8709fd9d2c3",
            "uuid_group"=>"4bf1205a-e030-4da9-ad16-6d4ac2c654c3",
            "type"=>"native", "notification"=>"You need more plugins.",
            "description"=>"Travis Insights description.",
            "description_link"=>"link",
            "test"=>"assert count($.Plugins) > 4",
            "base_object_locator"=>nil,
            "preconditions"=>nil,
            "conditionals"=>nil,
            "object_key_locator"=>nil,
            "active"=>true,
            "editable"=>false,
            "template_type"=>"TestDefinitions::Sre::YouNeedMorePlugins",
            "cruncher_type"=>"sreql",
            "status"=>"Active",
            "labels"=>{},
            "plugin_type"=>"sre",
            "plugin_type_name"=>"Travis Insights",
            "plugin_category"=>"Monitoring",
            "tag_list"=>[
              {
                "id"=>3,
                "name"=>"TI",
                "created_at"=>"2022-01-03T09:21:12.390Z",
                "updated_at"=>"2022-01-03T09:21:12.390Z",
                "taggings_count"=>1
              }
            ],
            "severity"=>"info"
          },
          {
            "@type"=>"insights_probe",
            "@representation"=>"standard",
            "id"=>313,
            "user_id"=>45,
            "user_plugin_id"=>nil,
            "test_template_id"=>313,
            "uuid"=>"f3abd5e4-8231-4afa-9b84-56bfa0264f34",
            "uuid_group"=>"d968832e-1b04-4b05-b810-884d0fb5fdee",
            "type"=>"native",
            "notification"=>"You need some deployment pipeline plugins.",
            "description"=>"Description",
            "description_link"=>"",
            "test"=>"assert count($.Plugins[@.plugin_category is \"deployment_pipeline\"]) > 0",
            "base_object_locator"=>nil,
            "preconditions"=>nil,
            "conditionals"=>nil,
            "object_key_locator"=>nil,
            "active"=>true,
            "editable"=>false,
            "template_type"=>"TestDefinitions::Sre::YouNeedSomeDeploymentPipelinePlugins",
            "cruncher_type"=>"sreql",
            "status"=>"Active",
            "labels"=>{},
            "plugin_type"=>"sre",
            "plugin_type_name"=>"Travis Insights",
            "plugin_category"=>"Monitoring",
            "tag_list"=>[],
            "severity"=>"high"
          }
        ]
      }
    end

    before do
      stub_insights_request(:get, '/probes', query: "page=#{page}", auth_key: insights_auth_key, user_id: user.id)
        .to_return(body: JSON.dump(insights_probes_response))
    end

    it 'responds with list of plugins' do
      get('/v3/insights_probes', {}, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
