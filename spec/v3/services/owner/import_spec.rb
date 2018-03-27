describe Travis::API::V3::Services::Owner::Import, set_app: true do
  describe "importing organization" do
    let(:user) { Factory.create(:user, login: 'merge-user') }
    let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org', github_id: 1234) }
    before    { org.save!  }
    after     { org.delete }
    before    { Travis::Features.activate_owner(:import_owner, org) }

    context "logged in" do
      let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
      let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}

      context "has admin permissions to an org" do
        before { Travis::API::V3::Models::Membership.create!(user: user, organization: org, role: "admin") }
        before do
          stub_request(:put, "https://merge.localhost/api/org/#{org.id}")
            .with { |request| request.body == {user_id: user.id}.to_json }
        end

        it "makes a request to the merge app" do
          response = post("/v3/owner/example-org/import", {}, headers)
          response.status.should == 202
          JSON.parse(response.body)['@href'].should == "/v3/org/#{org.id}"
        end

        context "when a :import_owner feature is disabled" do
          before { Travis::Features.deactivate_owner(:import_owner, org) }
          it "returns 403" do
            response = post("/v3/owner/example-org/import", {}, headers)
            response.status.should == 403
          end
        end
      end

      context "doesn't have admin permissions to an org" do
        before { Travis::API::V3::Models::Membership.create!(user: user, organization: org, role: "other") }

        it "returns a 403 response" do
          response = post("/v3/owner/example-org/import", {}, headers)
          response.status.should == 403
          JSON.parse(response.body)['@type'].should == "error"
        end
      end

      context "isn't the organization member" do
        it "returns a 403 response" do
          response = post("/v3/owner/example-org/import", {}, headers)
          response.status.should == 403
          JSON.parse(response.body)['@type'].should == "error"
        end
      end

    end
  end

  describe "importing user" do
    let!(:user) { Factory.create(:user, login: 'merge-user') }
    let!(:other_user) { Factory.create(:user, login: 'other-user') }
    before { Travis::Features.activate_owner(:import_owner, user) }

    context "logged in" do
      let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
      let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}

      context "when switching themselves" do
        before do
          stub_request(:put, "https://merge.localhost/api/user/#{user.id}")
            .with { |request| request.body == {user_id: user.id}.to_json }
        end

        it "makes a request to the merge app" do
          response = post("/v3/owner/merge-user/import", {}, headers)
          response.status.should == 202
          JSON.parse(response.body)['@href'].should == "/v3/user/#{user.id}"
        end

        context "when a :import_owner feature is disabled" do
          before { Travis::Features.deactivate_owner(:import_owner, user) }
          it "returns 403" do
            response = post("/v3/owner/merge-user/import", {}, headers)
            response.status.should == 403
          end
        end

      end

      context "when switching someone else" do
        it "returns a 403 response" do
          response = post("/v3/owner/other-user/import", {}, headers)
          response.status.should == 403
          JSON.parse(response.body)['@type'].should == "error"
        end
      end

      context "inexistent user" do
        it "returns a 403 response" do
          response = post("/v3/owner/foo-bar-baz-user/import", {}, headers)
          response.status.should == 404
          JSON.parse(response.body)['@type'].should == "error"
        end
      end

    end
  end
end
