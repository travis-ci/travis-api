describe Travis::API::V3::Services::InsightsTags::SearchTags, set_app: true, insights_spec_helper: true do
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
      get('/v3/insights_tags')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:expected_json) do
      {
        "@type"=>"tags",
        "@href"=>"/v3/insights_tags",
        "@representation"=>"standard",
        "tags"=>[
          {
            "@type"=>"insights_tag",
            "@representation"=>"standard",
            "name"=>"Tag1"
          },
          {
            "@type"=>"insights_tag",
            "@representation"=>"standard",
            "name"=>"Tag2"
          },
          {
            "@type"=>"insights_tag",
            "@representation"=>"standard",
            "name"=>"Tag3"
          }
        ]
      }
    end

    before do
      stub_insights_request(:get, '/tags', auth_key: insights_auth_key, user_id: user.id)
        .to_return(status: 201, body: JSON.dump(insights_tags_response))
    end

    it 'responds with authenticate result' do
      get('/v3/insights_tags', {}, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
