describe Travis::API::V3::Services::Organizations::ForCurrentUser, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
  before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
  before        { repo.update_attribute(:private, true)                             }
  after         { repo.update_attribute(:private, false)                            }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }
  let(:org_authorization) { { 'permissions' => [] } }
  let(:org_role_authorization) { { 'roles' => ['account_admin'] } }
  let(:repo_role_authorization) { { 'roles' => ['repository_admin'] } }
  before { stub_request(:get, %r((.+)/roles/org/(.+))).to_return(status: 200, body: JSON.generate(org_role_authorization)) }
  before { stub_request(:get, %r((.+)/roles/repo/(.+))).to_return(status: 200, body: JSON.generate(org_role_authorization)) }
  before { stub_request(:get, %r((.+)/permissions/org/(.+))).to_return(status: 200, body: JSON.generate(org_authorization)) }
  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }
  before { stub_request(:post, %r((.+)/usage/stats)) }

  let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org')   }
  before    { org.save!                                }
  before    { org.memberships.create(user: repo.owner, role: 'admin') }
  after     { org.delete                               }

  context "with role query param" do
    it "filters by role" do
      another_org = Travis::API::V3::Models::Organization.create(login: 'another-org')
      another_org.memberships.create(user: repo.owner, role: 'member')

      get("/v3/orgs", {role: 'admin'}, headers)
      expect(JSON.load(body)['organizations'].map { |o| o['id'] }).to eq([org.id])
    end
  end

  describe "authenticated as user with access" do

  let(:org_authorization) { { 'permissions' => ['account_billing_view','account_billing_update','account_plan_create','account_plan_view','account_plan_usage','account_plan_invoices','account_settings_create','account_settings_delete'] } }
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
        "@permissions"    => { 
          "read" => true, 
          "sync" => true, 
          "admin" => true,
          "plan_usage"=>true,
          "plan_view"=>true,
          "plan_create"=>true,
          "billing_update"=>true,
          "billing_view"=>true,
          "settings_delete"=>true,
          "settings_create"=>true,
          "plan_invoices"=>true
        },
        "id"              => org.id,
        "login"           => "example-org",
        "name"            => nil,
        "github_id"       => nil,
        "vcs_id"          => org.vcs_id,
        "vcs_type"        => org.vcs_type,
        "avatar_url"      => nil,
        "education"       => false,
        "allow_migration" => false,
        "trial_allowed"    => false,
        "ro_mode"         => true,
        "allowance" => {
          "@type"             => "allowance",
          "@representation"   => "minimal",
          "id"                => org.id
        },
        "custom_keys"     => []
      }]
    }}
  end
end
