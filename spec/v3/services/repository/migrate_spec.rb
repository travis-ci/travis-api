describe Travis::API::V3::Services::Repository::Migrate, set_app: true do
  describe "migrating a repository" do
    let(:user) { Factory.create(:user, login: 'merge-user') }
    let(:repo) { Travis::API::V3::Models::Repository.first }
    before    { Travis::Features.activate_owner(:allow_migration, repo.owner) }

    context "logged in" do
      let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
      let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}

      context "has admin permissions to the repo" do
        before { Travis::API::V3::Models::Permission.create(repository: repo, user: user, admin: true) }
        before do
          stub_request(:post, "https://merge.localhost/api/repository/#{repo.slug}/migrate")
        end

        it "makes a request to the merge app" do
          response = post("/v3/repo/#{repo.id}/migrate", {}, headers)
          response.status.should == 202
          JSON.parse(response.body)['@href'].should == "/v3/repo/#{repo.id}"
        end

        context "when repo is migrating" do
          before { repo.update_attributes(migration_status: "migrating") }
          before { post("/v3/repo/#{repo.id}/migrate", {}, headers) }

          example { expect(last_response.status).to be == 403 }
          example { expect(JSON.load(body)).to be == {
            "@type"         => "error",
            "error_type"    => "repo_migrated",
            "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
          }}
        end

        context "when repo has been migrated" do
          before { repo.update_attributes(migration_status: "migrated") }
          before { post("/v3/repo/#{repo.id}/migrate", {}, headers) }

          example { expect(last_response.status).to be == 403 }
          example { expect(JSON.load(body)).to be == {
            "@type"         => "error",
            "error_type"    => "repo_migrated",
            "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
          }}
        end

        context "when a :allow_migration feature is disabled" do
          before { Travis::Features.deactivate_owner(:allow_migration, repo.owner) }
          it "returns 403" do
            response = post("/v3/repo/#{repo.id}/migrate", {}, headers)
            response.status.should == 403
          end
        end
      end

      context "doesn't have admin permissions to the repository" do
        before { Travis::API::V3::Models::Permission.create(repository: repo, user: user, pull: true) }

        it "returns a 403 response" do
          response = post("/v3/repo/#{repo.id}/migrate", {}, headers)
          response.status.should == 403
          JSON.parse(response.body)['@type'].should == "error"
        end
      end
    end
  end
end
