describe Travis::API::V3::Services::Organizations::ForCurrentUser, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
  before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
  before        { repo.update_attribute(:private, true)                             }
  after         { repo.update_attribute(:private, false)                            }

  let(:org) { Factory(:org_v3, login: 'example-org')   }
  before    { org.save!                                }
  before    { org.memberships.create(user: repo.owner, role: 'admin') }
  after     { org.delete                               }

  context "with role query param" do
    it "filters by role" do
      another_org = Travis::API::V3::Models::Organization.create(login: 'another-org')
      another_org.memberships.create(user: repo.owner, role: 'member')

      get("/v3/orgs", {role: 'admin'}, headers)
      JSON.load(body)['organizations'].map { |o| o['id'] }.should == [org.id]
    end
  end

  describe "authenticated as user with access" do
    before  { get("/v3/orgs", {}, headers)     }
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"             => "organizations",
      "@href"             => "/v3/orgs",
      "@representation"   => "standard",
      "@pagination"       => {
        "limit"           => 100,
        "offset"          => 0,
        "count"           => 1,
        "is_first"        => true,
        "is_last"         => true,
        "next"            => nil,
        "prev"            => nil,
        "first"           => {
          "@href"         => "/v3/orgs",
          "offset"        => 0,
          "limit"         => 100},
          "last"          => {
            "@href"       => "/v3/orgs",
            "offset"      => 0,
            "limit"       => 100}},
      "organizations"     => [{
        "@type"           => "organization",
        "@href"           => "/v3/org/#{org.id}",
        "@representation" => "standard",
        "@permissions"    => { "read" => true, "sync" => true, "admin" => true },
        "id"              => org.id,
        "login"           => "example-org",
        "name"            => "travis-ci",
        "github_id"       => nil,
        "vcs_id"          => nil,
        "vcs_type"        => "GithubOrganization",
        "avatar_url"      => nil,
        "education"       => false,
        "allow_migration" => false,
      }]
    }}
  end
end
