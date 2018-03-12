require 'spec_helper'
describe Travis::API::V3::Services::Subscription::Find, set_app: true do
  let(:user) { Travis::API::V3::Models::User.create(login: 'example-user', github_id: 1234) }
  let(:valid_to) { Time.now.utc + 1.month }
  let(:subscription) { Travis::API::V3::Models::Subscription.create(owner: user, valid_to: valid_to,source: "stripe", status: "subscribed", selected_plan: "travis-ci-two-builds") }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}", "Content-Type" => "application/json" }}

  describe 'existing subscription' do
    before do
      get("/v3/subscription/#{subscription.id}", {}, headers)
    end
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"            => "subscription",
      "@representation"  => "standard",
      "id"               => subscription.id,
      "valid_to"         => subscription.valid_to.strftime('%Y-%m-%dT%H:%M:%SZ'),
      "first_name"       => nil,
      "last_name"        => nil,
      "company"          => nil,
      "zip_code"         => nil,
      "address"          => nil,
      "address2"         => nil,
      "city"             => nil,
      "state"            => nil,
      "country"          => nil,
      "vat_id"           => nil,
      "status"           => subscription.status,
      "source"           => subscription.source,
      "selected_plan"    => subscription.selected_plan
    }}
  end

end
