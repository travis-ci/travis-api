describe Travis::API::V3::Services::InsightsProbe::Get, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }
  let(:probe_id) { 1 }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get("/v3/insights_probe/#{probe_id}")

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:expected_json) do
      {
        "@type"=>"insights_probe",
        "@representation"=>"standard",
        "id"=>1,
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
    end

    before do
      stub_insights_request(:get, "/probes/#{probe_id}/template_test", query: "probe_id=#{probe_id}", auth_key: insights_auth_key, user_id: user.id)
        .to_return(status: 201, body: JSON.dump(insights_create_probe_response('id' => probe_id)))
    end

    it 'responds with authenticate result' do
      get("/v3/insights_probe/#{probe_id}", {}, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
