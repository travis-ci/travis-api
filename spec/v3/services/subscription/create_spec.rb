require 'spec_helper'
describe Travis::API::V3::Services::Subscription::Create, set_app: true do
  let(:user) { Travis::API::V3::Models::User.create(login: 'example-user', github_id: 1234) }
  let(:subscription_payload) {{
      'subscription' =>
        { 'owner_id'   => user.id,
          'selected_plan' => 'travis-ci-two-builds',
          'address'     => 'Rigaer St 8'}
    }}
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }

  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}", "Content-Type" => "application/json" }}

  before do
    Travis.config.billing = {url:'https://billing-v2-test.travis-ci.com'}
    ENV['BILLING_AUTH_KEY'] = 'abc123'
  end

  describe 'create subscription' do
    before do
      Travis::API::V3::Billing.any_instance.stubs(:create_subscription).returns({body: {id: '111'}, status: 200})
      stub_request(:post, "https://billing-v2-test.travis-ci.com/subscriptions").
         with(:body => {"subscription"=>{"owner_id"=>"4", "selected_plan"=>"travis-ci-two-builds", "address"=>"Rigaer St 8"}, "user_id"=>4},
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Basic YWRtaW46YWJjMTIz', 'Content-Type'=>'application/json', 'User-Agent'=>'Faraday v0.12.2'}).
         to_return(:status => 201, :body => "", :headers => {})
      post("/v3/subscription", subscription_payload, headers)
    end
    example { expect(last_response).to be_ok   }
    example { expect(last_response.status).to be 201 }
  end

end
