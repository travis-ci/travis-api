describe Travis::API::V3::Services::Organization::Find, set_app: true do
  let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org') }
  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }

  before    { org.save!                              }
  after     { org.delete                             }

  let(:org_authorization) { { 'permissions' => ['account_billing_view','account_billing_update','account_plan_create','account_plan_view','account_plan_usage','account_plan_invoices','account_settings_create','account_settings_delete'] } }
  let(:org_role_authorization) { { 'roles' => ['account_admin'] } }
  before { stub_request(:get, %r((.+)/roles/org/(.+))).to_return(status: 200, body: JSON.generate(org_role_authorization)) }
  before { stub_request(:get, %r((.+)/permissions/org/(.+))).to_return(status: 200, body: JSON.generate(org_authorization)) }
  before { stub_request(:post, %r((.+)/usage/stats)) }

  describe 'existing org, public api' do
    let(:org_role_authorization) { { 'roles' => [] } }
    let(:org_authorization) { { 'permissions' => [] } }
    before  { Travis.config.public_mode = true }
    before  { get("/v3/org/#{org.id}") }
    example { expect(last_response).to be_ok }
    example { expect(JSON.load(body)).to be == {
      "@type"            => "organization",
      "@href"            => "/v3/org/#{org.id}",
      "@representation"  => "standard",
      "@permissions"     => { 
        "read" => true, 
        "sync" => false, 
        "admin" => false,
        "plan_usage"=>false,
        "plan_view"=>false,
        "plan_create"=>false,
        "billing_update"=>false,
        "billing_view"=>false,
        "settings_delete"=>false,
        "settings_create"=>false,
        "plan_invoices"=>false
      },
      "id"               => org.id,
      "login"            => "example-org",
      "name"             => nil,
      "github_id"        => nil,
      "vcs_id"           => org.vcs_id,
      "vcs_type"         => org.vcs_type,
      "avatar_url"       => nil,
      "education"        => false,
      "allow_migration"  => false,
      "trial_allowed"    => false,
      "ro_mode"          => true,
      "allowance"        => {
        "@type"             => "allowance",
        "@representation"   => "minimal",
        "id"                => org.id
      },
      "custom_keys"      => []
    }}
  end

  describe 'existing educational org, private api, authorized user' do
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:org_role_authorization) { { 'roles' => [] } }
    let(:org_authorization) { { 'permissions' => ['account_billing_view', 'account_plan_invoices', 'account_plan_usage', 'account_plan_view', 'account_settings_create', 'account_settings_delete'] } }
    before  do
      org.memberships.create(user: user)
      org.save!
      allow(Travis::Features).to receive(:owner_active?).and_return(true)
      allow(Travis::Features).to receive(:owner_active?).with(:educational_org, org).and_return(true)
      Travis.config.public_mode = false
    end
    before  { get("/v3/org/#{org.id}", {}, headers) }
    after   { Travis.config.public_mode = true }
    example { expect(JSON.load(body)).to be ==      {
      "@type"            => "organization",
      "@href"            => "/v3/org/#{org.id}",
      "@representation"  => "standard",
      "@permissions"     => {
        "read" => true,
        "sync" => false,
        "admin" => false,
        "plan_usage"=>true,
        "plan_view"=>true,
        "plan_create"=>false,
        "billing_update"=>false,
        "billing_view"=>true,
        "settings_delete"=>true,
        "settings_create"=>true,
        "plan_invoices"=>true
      },
      "id"               => org.id,
      "login"            => "example-org",
      "name"             => nil,
      "github_id"        => nil,
      "vcs_id"           => org.vcs_id,
      "vcs_type"         => org.vcs_type,
      "avatar_url"       => nil,
      "education"        => true,
      "allow_migration"  => true,
      "trial_allowed"    => false,
      "ro_mode"          => false,
      "allowance"        => {
        "@type"             => "allowance",
        "@representation"   => "minimal",
        "id"                => org.id
      },
      "custom_keys"      => []
    }}
  end

  describe 'existing org, private api' do
    before  { Travis.config.public_mode = false }
    before  { get("/v3/org/#{org.id}") }
    after   { Travis.config.public_mode = true }
    example { expect(last_response).to be_not_found }
    example { expect(JSON.load(body)).to be ==      {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "organization not found (or insufficient access)",
      "resource_type" => "organization"
    }}
  end
end
