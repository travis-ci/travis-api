describe Travis::API::V3::Services::Repository::Find, set_app: true do
  let(:user) { User.where(login: 'svenfuchs').first }
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:jobs)  { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:parsed_body) { JSON.load(body) }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  let(:authorization_role) { { 'roles' => ['repository_admin'] } }

  before do
    stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) 
    stub_request(:get, %r((.+)/roles/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization_role))
    stub_request(:post,  'http://billingfake.travis-ci.com/usage/stats')
      .with(body: "{\"owners\":[{\"id\":1,\"type\":\"User\"}],\"query\":\"trial_allowed\"}")
      .to_return(status: 200, body: "{\"trial_allowed\": false }", headers: {})
  end

  let(:permissions) do
    {
      admin: {
        "read"             => true,
        "activate"         => true,
        "deactivate"       => true,
        "migrate"          => false, # allow_migration is disabled
        "star"             => true,
        "unstar"           => true,
        "create_request"   => true,
        "create_cron"      => true,
        "create_env_var"   => true,
        "create_key_pair"  => true,
        "delete_key_pair"  => true,
        "check_scan_results" => true,
        "build_cancel"     => true,
        "build_create"     => true,
        "build_debug"      => true,
        "build_restart"    => true,
        "cache_delete"     => true,
        "cache_view"       => true,
        "settings_create"  => true,
        "settings_delete"  => true,
        "settings_read"    => true,
        "settings_update"  => true,
        "log_delete"       => true,
        "log_view"         => true,
        "admin"            => true
      },
      full_access: {
        "read"             => true,
        "activate"         => true,
        "deactivate"       => true,
        "migrate"          => false,
        "star"             => true,
        "unstar"           => true,
        "create_request"   => true,
        "create_cron"      => true,
        "create_env_var"   => true,
        "create_key_pair"  => true,
        "delete_key_pair"  => true,
        "check_scan_results" => true,
        "build_cancel"     => true,
        "build_create"     => true,
        "build_debug"      => true,
        "build_restart"    => true,
        "cache_delete"     => true,
        "cache_view"       => true,
        "settings_create"  => true,
        "settings_delete"  => true,
        "settings_read"    => true,
        "settings_update"  => true,
        "log_delete"       => true,
        "log_view"         => true,
        "admin"            => false
      },
      read_and_star: {
        "read"             => true,
        "activate"         => false,
        "deactivate"       => false,
        "migrate"          => false,
        "star"             => true,
        "unstar"           => true,
        "create_request"   => false,
        "create_cron"      => false,
        "create_env_var"   => false,
        "create_key_pair"  => false,
        "delete_key_pair"  => false,
        "check_scan_results" => false,
        "build_cancel"     => false,
        "build_create"     => false,
        "build_debug"      => false,
        "build_restart"    => false,
        "cache_delete"     => false,
        "cache_view"       => false,
        "settings_create"  => false,
        "settings_delete"  => false,
        "settings_read"    => true,
        "settings_update"  => false,
        "log_delete"       => false,
        "log_view"         => true,
        "admin"            => false
      },
      read: {
        "read"             => true,
        "activate"         => false,
        "deactivate"       => false,
        "migrate"          => false,
        "star"             => false,
        "unstar"           => false,
        "create_request"   => false,
        "create_cron"      => false,
        "create_env_var"   => false,
        "create_key_pair"  => false,
        "delete_key_pair"  => false,
        "check_scan_results" => false,
        "build_cancel"     => false,
        "build_create"     => false,
        "build_debug"      => false,
        "build_restart"    => false,
        "cache_delete"     => false,
        "cache_view"       => false,
        "settings_create"  => false,
        "settings_delete"  => false,
        "settings_read"    => true,
        "settings_update"  => false,
        "log_delete"       => false,
        "log_view"         => true,
        "admin"            => false
      }
    }
  end

  shared_examples '200 standard representation' do |opts|
    example { expect(last_response).to be_ok }
    example { expect(parsed_body).to eql_json({
      "@type"              => "repository",
      "@href"              => "/v3/repo/#{repo.id}",
      "@representation"    => "standard",
      "@permissions"       => permissions[opts[:permissions]],
      "id"                 => repo.id,
      "name"               => "minimal",
      "slug"               => "svenfuchs/minimal",
      "description"        => nil,
      "github_id"          => repo.github_id,
      "vcs_id"             => repo.vcs_id,
      "vcs_type"           => repo.vcs_type,
      "owner_name"         => "svenfuchs",
      "vcs_name"           => "minimal",
      "github_language"    => nil,
      "active"             => true,
      "private"            => opts[:private],
      "server_type"        => 'git',
      "shared"             => false,
      "scan_failed_at"     => nil,
      "owner"              => {
        "id"               => repo.owner_id,
        "login"            => "svenfuchs",
        "@type"            => "user",
        "ro_mode"          => true,
        "@href"            => "/v3/user/#{repo.owner_id}"},
      "default_branch"     => {
        "@type"            => "branch",
        "@href"            => "/v3/repo/#{repo.id}/branch/master",
        "@representation"  => "minimal",
        "name"             => "master"},
      "starred"            => false,
      "active_on_org"      => nil,
      "managed_by_installation" => false,
      "migration_status"   => nil,
      "history_migration_status" => nil,
      "config_validation"  => false
    })}
  end

  shared_examples '404 not found' do
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    })}
  end

  shared_examples '400 wrong params' do |message|
    example { expect(last_response.status).to be == 400 }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => message
    })}
  end

  describe "fetching a non-existing repository by slug" do
    before { get("/v3/repo/svenfuchs%2Fminimal1") }
    include_examples '404 not found'
  end

  describe "fetching a case sensitive repository by slug Minimal when minimal and Minimal (newer) are defined" do
    before {
      Travis::API::V3::Models::Repository.create!(
        id: 12345,
        name: 'Minimal',
        url: "http://github.com/svenfuchs/Minimal",
        owner_name: "svenfuchs",
        owner_email: "svenfuchs@artweb-design.de",
        updated_at: '2119-08-09 00:00:00',
        active: true,
        private: false,
        owner_id: 1,
        owner_type: "User",
        last_build_state: "passed",
        github_id: 12345,
        server_type: 'git'
      )
      get("/v3/repo/svenfuchs%2FMinimal")
    }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body['slug']).to be == 'svenfuchs/Minimal' }
    example { expect(parsed_body['id']).to be == 12345 }
  end

  describe "missing repository" do
    before  { get("/v3/repo/999999999999999") }
    include_examples '404 not found'
  end

  shared_examples 'private repo' do
    before { repo.update_attribute(:private, true) }
    after  { repo.update_attribute(:private, false) }
  end

  shared_examples 'authenticated as a user without permissions' do
    let(:token)   { Travis::Api::App::AccessToken.create(user: User.find(2), app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  end

  shared_examples 'authenticated as a user with permissions' do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, admin: false) }
    let(:authorization_role) { { 'roles' => [] } }
  end

  shared_examples 'authenticated as a user with admin permissions' do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, admin: true) }
  end

  shared_examples 'authenticated as as internal application with full access' do |opts|
    let(:app_name)   { 'travis-example' }
    let(:app_secret) { '12345678' }
    let(:sign_opts)  { "a=#{app_name}" }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts) }
    let(:headers)    { { 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}" } }
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret } } }
  end

  shared_examples 'allows unauthenticated access to a public repo' do
    describe 'public repo' do
      before { get("/v3/repo/#{repo.id}") }
      let(:authorization_role) { { 'roles' => [] } }
      include_examples '200 standard representation', permissions: :read, private: false
    end

    describe 'public repo by slug' do
      before  { get("/v3/repo/svenfuchs%2Fminimal") }
      example { expect(last_response).to be_ok }
      example { expect(parsed_body['slug']).to be == 'svenfuchs/minimal' }
    end
  end

  shared_examples 'denies unauthenticated access to a public repo' do
    describe 'public repo' do
      before { get("/v3/repo/#{repo.id}") }
      include_examples '404 not found'
    end

    describe 'public repo by slug' do
      before  { get("/v3/repo/svenfuchs%2Fminimal") }
      include_examples '404 not found'
    end
  end

  shared_examples 'denies unauthenticated access to a private repo' do
    describe 'private repo' do
      include_examples 'private repo'
      before { get("/v3/repo/#{repo.id}") }
      include_examples '404 not found'
    end
  end

  shared_examples 'allows access to a public repo to a user with permissions' do
    describe 'public repo as a user with permissions' do
      include_examples 'authenticated as a user with permissions'
      before { get("/v3/repo/#{repo.id}", {}, headers) }

      let(:authorization_role) { { 'roles' => [] } }
      include_examples '200 standard representation', permissions: :read_and_star, private: false
    end
  end

  shared_examples 'allows access to a private repo to a user with permissions' do
    describe 'private repo as a user with permissions' do
      include_examples 'private repo'
      include_examples 'authenticated as a user with permissions'
      before { get("/v3/repo/#{repo.id}", {}, headers) }

      let(:authorization_role) { { 'roles' => [] } }
      include_examples '200 standard representation', permissions: :read_and_star, private: true
    end
  end

  shared_examples 'allows access to a public repo to a user without permissions' do
    describe 'public repo as a user without permissions' do
      include_examples 'authenticated as a user without permissions'
      before { get("/v3/repo/#{repo.id}", {}, headers) }

      let(:authorization_role) { { 'roles' => [] } }
      include_examples '200 standard representation', permissions: :read, private: false
    end
  end

  shared_examples 'denies access to a public repo to a user without permissions' do
    describe 'private repo as a user without permissions' do
      include_examples 'authenticated as a user without permissions'
      before { get("/v3/repo/#{repo.id}", {}, headers) }
      include_examples '404 not found'
    end
  end

  shared_examples 'denies access to a private repo to a user without permissions' do
    describe 'private repo as a user without permissions' do
      include_examples 'private repo'
      include_examples 'authenticated as a user without permissions'
      before { get("/v3/repo/#{repo.id}", {}, headers) }
      include_examples '404 not found'
    end
  end

  shared_examples 'private mode' do
    describe 'anonymous request' do
      include_examples 'denies unauthenticated access to a public repo'
      include_examples 'denies unauthenticated access to a private repo'
    end

    describe 'authenticated as a user without permissions' do
      include_examples 'denies access to a public repo to a user without permissions'
      include_examples 'denies access to a private repo to a user without permissions'
    end

    describe 'authenticated as a user with permissions' do
      include_examples 'allows access to a public repo to a user with permissions'
      include_examples 'allows access to a private repo to a user with permissions'
    end
  end

  shared_examples 'public mode' do
    describe 'anonymous request' do
      include_examples 'allows unauthenticated access to a public repo'
      include_examples 'denies unauthenticated access to a private repo'
    end

    describe 'authenticated as a user without permissions' do
      include_examples 'allows access to a public repo to a user without permissions'
      include_examples 'denies access to a private repo to a user without permissions'
    end

    describe 'authenticated as a user with permissions' do
      include_examples 'allows access to a public repo to a user with permissions'
      include_examples 'allows access to a private repo to a user with permissions'
    end
  end

  after { Travis.config.public_mode = true }

  describe 'config.public_mode being false' do
    before { Travis.config.public_mode = false }

    let(:authorization) { { 'permissions' => ['repository_log_view', 'repository_settings_read'] } }
    include_examples 'private mode'
  end

  describe 'config.public_mode being unset (defaults to false)' do
    before { Travis.config.public_mode = nil }

    let(:authorization) { { 'permissions' => ['repository_log_view', 'repository_settings_read'] } }
    include_examples 'private mode'
  end

  describe 'config.public_mode being true' do
    before { Travis.config.public_mode = true }
    let(:authorization_role) { { 'roles' => [] } }
    let(:authorization) { { 'permissions' => ['repository_log_view', 'repository_settings_read'] } }
    include_examples 'public mode'
  end

  describe 'feature flag public_mode enabled for the repo owner' do
    before { Travis.config.public_mode = false }
    before { Travis::Features.activate_owner(:public_mode, repo.owner) }
    after  { Travis::Features.deactivate_owner(:public_mode, repo.owner) }

    let(:authorization) { { 'permissions' => ['repository_log_view', 'repository_settings_read'] } }
    let(:authorization_role) { { 'roles' => [] } }
    include_examples 'public mode'
  end

  describe "private repository without cron feature, authenticated as internal application with full access" do
    let(:app_name)   { 'travis-example' }
    let(:app_secret) { '12345678' }
    let(:sign_opts)  { "a=#{app_name}" }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts) }
    let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}" }}
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}

    before { repo.update_attribute(:private, true) }
    before { get("/v3/repo/#{repo.id}", {}, headers) }
    before { repo.update_attribute(:private, false) }

    let(:authorization_role) { { 'roles' => [] } }
    include_examples '200 standard representation', permissions: :full_access, private: true
  end

  describe "private repository, authenticated as internal application with full access, but scoped to a different org" do
    let(:app_name)   { 'travis-example' }
    let(:app_secret) { '12345678' }
    let(:sign_opts)  { "a=#{app_name}:s=travis-pro" }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts) }
    let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}" }}
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}

    before { repo.update_attribute(:private, true) }
    before { get("/v3/repo/#{repo.id}", {}, headers) }
    before { repo.update_attribute(:private, false) }

    include_examples '404 not found'
  end

  describe "private repository without cron feature, authenticated as user with admin access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}

    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, push: true, admin: true) }
    before { repo.update_attribute(:private, true) }
    before { get("/v3/repo/#{repo.id}", {}, headers) }

    include_examples '200 standard representation', permissions: :admin, private: true
  end

  describe "including full owner" do
    before  { get("/v3/repo/#{repo.id}?include=repository.owner") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body['owner']).to include("github_id", "is_syncing", "synced_at",
      "@type" => "user",
      "id"    => repo.owner_id,
      "login" => "svenfuchs",
    )}
  end

  describe 'representation internal' do
    shared_examples 'responds with the internal representation' do |opts|
      it { expect(parsed_body['@representation']).to eq 'internal' }
      it { expect(parsed_body['token']).to eq token }
      it { expect(parsed_body['private_key']).to include 'RSA PRIVATE KEY' }
      it { expect(parsed_body['user_settings']['@type']).to eq 'settings' }
    end

    shared_examples 'responds with the standard representation' do |opts|
      it { expect(parsed_body['@representation']).to eq 'standard' }
      it { expect(parsed_body['token']).to be_nil }
      it { expect(parsed_body['private_key']).to be_nil }
      it { expect(parsed_body['user_settings']).to be_nil }
    end

    describe 'authenticated as internal application with full access' do
      describe 'managed by oauth token' do
        let(:token) { 'github_oauth_token' }
        include_examples 'authenticated as as internal application with full access'
        before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, admin: true) }
        before { get("/v3/repo/#{repo.id}?representation=internal", {}, headers) }
        include_examples 'responds with the internal representation'
      end

      describe 'managed by github installation' do
        let(:token) { 'app_token' }
        include_examples 'authenticated as as internal application with full access'
        before { Travis::API::V3::Models::Installation.create(owner: repo.owner, github_id: 1) }
        before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, admin: true) }
        before { stub_request(:post, 'https://api.github.com/app/installations/1/access_tokens').to_return(status: 201, body: JSON.dump(token: 'app_token')) }
        before { get("/v3/repo/#{repo.id}?representation=internal", {}, headers) }
        include_examples 'responds with the internal representation'
      end
    end

    describe 'anonymous' do
      before { get("/v3/repo/#{repo.id}?representation=internal") }
      include_examples 'responds with the standard representation'
    end

    describe 'authenticated as a user with admin permissions' do
      include_examples 'authenticated as a user with admin permissions'
      before { get("/v3/repo/#{repo.id}?representation=internal") }
      include_examples 'responds with the standard representation'
    end
  end

  describe "including full owner" do
    before  { get("/v3/repo/#{repo.id}?include=repository.owner") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body['owner']).to include("github_id", "is_syncing", "synced_at")}
  end

  describe "when owner is missing" do
    before  { repo.update_attribute(:owner, nil)                  }
    before  { get("/v3/repo/#{repo.id}?include=repository.owner") }
    example { expect(last_response).to be_not_found               }
  end

  describe "including non-existing field" do
    before { get("/v3/repo/#{repo.id}?include=repository.owner,repository.last_build_number") }
    include_examples '400 wrong params', 'no field "repository.last_build_number" to include'
  end

  describe "wrong include format" do
    before  { get("/v3/repo/#{repo.id}?include=repository.last_build.branch") }
    include_examples '400 wrong params', 'illegal format for include parameter'
  end

  describe "repo managed by a github installation" do
    before { repo.update_attribute(:managed_by_installation_at, "2017-11-12T12:00:00Z") }
    before  { get("/v3/repo/#{repo.id}") }
    example { expect(parsed_body).to include("managed_by_installation" => true )}
  end
end
