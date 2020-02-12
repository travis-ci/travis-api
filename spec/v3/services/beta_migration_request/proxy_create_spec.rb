require 'spec_helper'

describe Travis::API::V3::Services::BetaMigrationRequest::ProxyCreate, set_app: true do
  let(:user)  { Travis::API::V3::Models::User.where(login: 'svenfuchs').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:params) { {} }

  let!(:org1) { FactoryBot.create(:org_v3, name: "org_1")}
  let!(:org2) { FactoryBot.create(:org_v3, name: "org_2")}
  let!(:org3) { FactoryBot.create(:org_v3, name: "org_3")}

  let(:valid_org_ids) { [org1.id, org2.id, org3.id]}
  let(:valid_orgs) { [org1, org2, org3]}

  let(:invalid_org) { FactoryBot.create(:org_v3, name: "invalid_org") }

  before do
    valid_org_ids.each do |org_id|
      FactoryBot.create(:membership, role: "admin", organization_id: org_id, user_id: user.id)
    end

    Travis.config.applications[:api_org] = { token: 'sometoken', full_access: true }
  end

  after do
    Travis.config.applications.delete(:api_org)
  end

  describe 'not authenticated' do
    before { post("/v3/user/#{user.id}/beta_migration_request", params) }
    include_examples 'not authenticated'
  end

  describe "missing user, authenticated" do
    before        { post("/v3/user/9999999999/beta_migration_request", params, auth_headers) }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "user not found (or insufficient access)",
      "resource_type" => "user"
    }}
  end

  describe "existing user, matches current user " do
    let(:response_hash) do
      {
        "@type"           => "beta_migration_request",
        "@representation" =>"standard",
        "owner_id"        => user.id,
        "owner_name"      => user.login,
        "owner_type"      => "User"
      }
    end

    before do
      Travis::API::V3::Models::Permission.create(user: user)
      stub_request(:post, "#{Travis.config.api_com_url}/v3/beta_migration_requests").to_return(status: 200, body: response_hash.to_json)
      post("/v3/user/#{user.id}/beta_migration_request", params, auth_headers)
    end

    example { expect(last_response.status).to be == 200 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "@representation",
      "id",
      "owner_id",
      "owner_name",
      "owner_type")
    }

    example { expect(JSON.load(body)).to include(response_hash) }
  end
end
