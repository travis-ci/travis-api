require 'spec_helper'

describe Travis::API::V3::Services::BetaMigrationRequests::Create, set_app: true do
  let(:user)  { FactoryBot.create(:user, login: 'some_beta_user') }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => 'internal some_app:sometoken' } }
  let(:params)  { { user_login: user.login, organizations: valid_org_names } }

  let!(:org1) { FactoryBot.create(:org_v3, name: "org_1", login: "org_1")}
  let!(:org2) { FactoryBot.create(:org_v3, name: "org_2", login: "org_2")}
  let!(:org3) { FactoryBot.create(:org_v3, name: "org_3", login: "org_3")}

  let(:valid_org_names) { [org1.login, org2.login, org3.login]}
  let(:valid_orgs) { [org1, org2, org3]}

  let(:invalid_org) { FactoryBot.create(:org_v3, name: "invalid_org") }

  before do
    Travis.config.applications[:some_app] = { token: 'sometoken', full_access: true }

    valid_orgs.each do |org|
      FactoryBot.create(:membership, role: "admin", organization_id: org.id, user_id: user.id)
    end
  end

  after do
    Travis.config.applications.delete(:some_app)
  end

  describe "authenticated" do
    before do
      post("/v3/beta_migration_requests", params, auth_headers)
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

    example { expect(JSON.load(body)).to include(
      "@type"           => "beta_migration_request",
      "@representation" => "standard",
      "owner_id"        => user.id,
      "owner_name"      => user.login,
      "owner_type"      => "User")
    }

    context "when user has admin access to orgs they have selected" do
      let(:params)  { { user_login: user.login, organizations: valid_org_names } }

      it "selects all the orgs selected by the user" do
        selected_org_names = Travis::API::V3::Models::BetaMigrationRequest.where(owner_id: user.id).last.organizations.pluck(:login)

        expect(valid_org_names & selected_org_names).to eq valid_org_names
      end
    end

    context "when user does not have admin access to some orgs they have selected" do
      let(:params)  { { user_login: user.login, organizations: valid_org_names + [invalid_org.id] } }

      it "selects only the valid orgs selected by the user" do
        selected_org_names = Travis::API::V3::Models::BetaMigrationRequest.where(owner_id: user.id).last.organizations.pluck(:login)

        expect(valid_org_names & selected_org_names).to eq valid_org_names
      end

      it "does not enable beta for invalid orgs selected by the user" do
        selected_org_names = Travis::API::V3::Models::BetaMigrationRequest.where(owner_id: user.id).last.organizations.pluck(:login)
        expect(selected_org_names).to_not include invalid_org
      end
    end
  end
end
