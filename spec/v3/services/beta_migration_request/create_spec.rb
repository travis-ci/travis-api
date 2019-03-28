require 'spec_helper'

describe Travis::API::V3::Services::BetaMigrationRequest::Create, set_app: true do
  let(:user)  { Travis::API::V3::Models::User.where(login: 'svenfuchs').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:params) { {} }

  let!(:org1) { Factory(:org_v3, name: "org_1")}
  let!(:org2) { Factory(:org_v3, name: "org_2")}
  let!(:org3) { Factory(:org_v3, name: "org_3")}

  let(:valid_org_ids) { [org1.id, org2.id, org3.id]}
  let(:valid_orgs) { [org1, org2, org3]}

  let(:invalid_org) { Factory(:org_v3, name: "invalid_org") }

  before do
    valid_org_ids.each do |org_id|
      Factory(:membership, role: "admin", organization_id: org_id, user_id: user.id)
    end
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
8
  describe "existing user, matches current user " do
    before { Travis::API::V3::Models::Permission.create(user: user) }
    before { post("/v3/user/#{user.id}/beta_migration_request", params, auth_headers) }

    example { expect(last_response.status).to be == 200 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "@representation",
      "id",
      "owner_id",
      "owner_name",
      "owner_type")
    }

    example { expect(JSON.load(body)).to include(
      "@type"           => "beta_migration_request",
      "@representation" =>"standard",
      "owner_id"        => user.id,
      "owner_name"      => user.login,
      "owner_type"      => "User")
    }

    context "when user has admin access to orgs they have selected" do
      let(:params)  {{organizations: valid_org_ids}}

      it "selects all the orgs selected by the user" do
        selected_org_ids = Travis::API::V3::Models::BetaMigrationRequest.where(owner_id: user.id).last.organizations.pluck(:id)

        expect(valid_org_ids & selected_org_ids).to eq valid_org_ids
      end
    end

    context "when user does not have admin access to some orgs they have selected" do
      let(:params)  { {organizations: valid_org_ids + [invalid_org.id]} }

      it "selects only the valid orgs selected by the user" do
        selected_org_ids = Travis::API::V3::Models::BetaMigrationRequest.where(owner_id: user.id).last.organizations.pluck(:id)

        expect(valid_org_ids & selected_org_ids).to eq valid_org_ids
      end

      it "does not enable beta for invalid orgs selected by the user" do
        selected_org_ids = Travis::API::V3::Models::BetaMigrationRequest.where(owner_id: user.id).last.organizations.pluck(:id)
        expect(selected_org_ids).to_not include invalid_org
      end
    end
  end
end
