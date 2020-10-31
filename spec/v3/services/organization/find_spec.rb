describe Travis::API::V3::Services::Organization::Find, set_app: true do
  let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org') }
  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }

  before    { org.save!                              }
  after     { org.delete                             }

  describe 'existing org, public api' do
    before  { Travis.config.public_mode = true }
    before  { get("/v3/org/#{org.id}") }
    example { expect(last_response).to be_ok }
    example { expect(JSON.load(body)).to be == {
      "@type"            => "organization",
      "@href"            => "/v3/org/#{org.id}",
      "@representation"  => "standard",
      "@permissions"     => { "read" => true, "sync" => false, "admin" => false },
      "id"               => org.id,
      "login"            => "example-org",
      "name"             => nil,
      "github_id"        => nil,
      "vcs_id"           => org.vcs_id,
      "vcs_type"         => org.vcs_type,
      "avatar_url"       => nil,
      "education"        => false,
      "allow_migration"  => false,
      "allowance"        => {
        "@type"             => "allowance",
        "@representation"   => "minimal",
        "id"                => org.id
      }
    }}
  end

  describe 'existing educational org, private api, authorized user' do
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
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
      "@permissions"     => { "read" => true, "sync" => true, "admin" => false },
      "id"               => org.id,
      "login"            => "example-org",
      "name"             => nil,
      "github_id"        => nil,
      "vcs_id"           => org.vcs_id,
      "vcs_type"         => org.vcs_type,
      "avatar_url"       => nil,
      "education"        => true,
      "allow_migration"  => true,
      "allowance"        => {
        "@type"             => "allowance",
        "@representation"   => "minimal",
        "id"                => org.id
      }
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
