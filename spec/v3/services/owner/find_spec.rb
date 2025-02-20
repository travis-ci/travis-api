describe Travis::API::V3::Services::Owner::Find, set_app: true do

  before { stub_request(:post, %r((.+)/usage/stats)) }
  describe "organization" do
    let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org', github_id: 1234) }

    before    { org.save! }
    after     { org.delete                             }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  let(:org_authorization) { { 'permissions' => [] } }

  let(:org_role_authorization) { { 'roles' => ['account_admin'] } }

  let(:repo_role_authorization) { { 'roles' => ['repository_admin'] } }

  before { stub_request(:get, %r((.+)/roles/org/(.+))).to_return(status: 200, body: JSON.generate(org_role_authorization)) }

  before { stub_request(:get, %r((.+)/roles/repo/(.+))).to_return(status: 200, body: JSON.generate(org_role_authorization)) }
  before { stub_request(:get, %r((.+)/permissions/org/(.+))).to_return(status: 200, body: JSON.generate(org_authorization)) }
  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

    describe 'existing org, public api, by login' do
      let(:authorization) { { 'permissions' => ['repository_settings_read', 'repository_log_view'] } }
      let(:org_role_authorization) { { 'roles' => [] } }
      before  { get("/v3/owner/example-org")     }
      example { expect(last_response).to be_ok   }
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
        "github_id"        => 1234,
        "vcs_id"           => org.vcs_id,
        "vcs_type"         => org.vcs_type,
        "trial_allowed"    => false,
        "ro_mode"          => true,
        "avatar_url"       => nil,
        "education"        => false,
        "allow_migration"  => false,
        "allowance"        => {
          "@type"             => "allowance",
          "@representation"   => "minimal",
          "id"                => org.id
        },
        "custom_keys"      => []
      }}
    end

    describe 'existing org, public api, by github_id' do

      let(:authorization) { { 'permissions' => ['repository_settings_read', 'repository_log_view'] } }
      let(:org_role_authorization) { { 'roles' => [] } }
      before  { get("/v3/owner/github_id/1234")     }
      example { expect(last_response).to be_ok   }
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
        "github_id"        => 1234,
        "vcs_id"           => org.vcs_id,
        "vcs_type"         => org.vcs_type,
        "trial_allowed"    => false,
        "ro_mode"          => true,
        "avatar_url"       => nil,
        "education"        => false,
        "allow_migration"  => false,
        "allowance"        => {
          "@type"             => "allowance",
          "@representation"   => "minimal",
          "id"                => org.id
        },
        "custom_keys"      => []
      }}
    end

    describe 'eager loading repositories via organization.repositories' do
      let(:repo) { Travis::API::V3::Models::Repository.new(name: 'example-repo', owner_name: 'example-org', owner_id: org.id, owner_type: 'Organization')}

      before { repo.save!   }
      after  { repo.destroy }

      let(:authorization) { { 'permissions' => ['repository_settings_read', 'repository_log_view'] } }
      let(:org_role_authorization) { { 'roles' => [] } }
      before  { get("/v3/owner/example-org?include=organization.repositories,user.repositories") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"               => "organization",
        "@href"               => "/v3/org/#{org.id}",
        "@representation"     => "standard",
        "@permissions"        => {
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
        "id"                  => org.id,
        "login"               => "example-org",
        "name"                => nil,
        "github_id"           => 1234,
        "vcs_id"              => org.vcs_id,
        "vcs_type"            => org.vcs_type,
        "trial_allowed"       => false,
        "ro_mode"             => true,
        "avatar_url"          => nil,
        "education"           => false,
        "allow_migration"     => false,
        "allowance"           => {
          "@type"             => "allowance",
          "@representation"   => "minimal",
          "id"                => org.id
        },
        "custom_keys"         => [],
        "repositories"        => [{
          "@type"             => "repository",
          "@href"             => "/v3/repo/#{repo.id}",
          "@representation"   => "standard",
          "@permissions"      => {
            "read"            => true,
            "activate"        => false,
            "deactivate"      => false,
            "migrate"         => false,
            "star"            => false,
            "unstar"          => false,
            "create_request"  => false,
            "create_cron"     => false,
            "create_env_var"  => false,
            "create_key_pair" => false,
            "delete_key_pair" => false,
            "check_scan_results" => false,
            "admin"           => false,
            "log_delete"      =>false,
            "log_view"        =>true,
            "cache_delete"    =>false,
            "cache_view"      =>false,
            "build_debug"     =>false,
            "build_restart"   =>false,
            "build_create"    =>false,
            "build_cancel"    =>false,
            "settings_delete" =>false,
            "settings_create" =>false,
            "settings_update" =>false,
            "settings_read"   =>true
          },
          "id"                => repo.id,
          "name"              => "example-repo",
          "slug"              => "example-org/example-repo",
          "description"       => nil,
          "github_id"         => repo.github_id,
          "vcs_id"            => repo.vcs_id,
          "vcs_type"          => repo.vcs_type,
          "owner_name"        => "example-org",
          "vcs_name"          => "example-repo",
          "github_language"   => nil,
          "active"            => false,
          "private"           => false,
          "server_type"       => 'git',
          "shared"            => false,
          "scan_failed_at"    => nil,
          "owner"             => { "@href"=> "/v3/org/#{org.id}" },
          "default_branch"    => {
            "@type"           => "branch",
            "@href"           => "/v3/repo/#{repo.id}/branch/master",
            "@representation" => "minimal",
            "name"            => "master"},
          "starred"           => false,
          "managed_by_installation"=>false,
          "active_on_org"     => nil,
          "migration_status"  => nil,
          "history_migration_status"  => nil,
          "config_validation" => false
        }]
      }}
    end

    describe 'eager loading repositories via owner.repositories' do
      let(:repo) { Travis::API::V3::Models::Repository.new(name: 'example-repo', owner_name: 'example-org', owner_id: org.id, owner_type: 'Organization')}

      before { repo.save!   }
      after  { repo.destroy }

      let(:authorization) { { 'permissions' => ['repository_settings_read', 'repository_log_view'] } }
      let(:org_role_authorization) { { 'roles' => [] } }
      before  { get("/v3/owner/example-org?include=owner.repositories") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"             => "organization",
        "@href"             => "/v3/org/#{org.id}",
        "@representation"   => "standard",
        "@permissions"      => {
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
        "id"                => org.id,
        "login"             => "example-org",
        "name"              => nil,
        "github_id"         => 1234,
        "vcs_id"            => org.vcs_id,
        "vcs_type"          => org.vcs_type,
        "trial_allowed"     => false,
        "ro_mode"           => true,
        "avatar_url"        => nil,
        "education"         => false,
        "allow_migration"   => false,
        "allowance"         => {
          "@type"             => "allowance",
          "@representation"   => "minimal",
          "id"                => org.id
        },
        "custom_keys"       => [],
        "repositories"      => [{
          "@type"           => "repository",
          "@href"           => "/v3/repo/#{repo.id}",
          "@representation" => "standard",
          "@permissions"    => {
            "read"          => true,
            "log_delete"      =>false,
            "cache_delete"    =>false,
            "cache_view"      =>false,
            "build_debug"     =>false,
            "admin"         => false,
            "settings_delete" =>false,
            "settings_create" =>false,
            "activate"      => false,
            "deactivate"    => false,
            "migrate"       => false,
            "star"          => false,
            "unstar"        => false,
            "create_cron"   => false,
            "create_env_var"  => false,
            "create_key_pair" => false,
            "delete_key_pair" => false,
            "create_request"=> false,
            "check_scan_results" => false,
            "settings_update" =>false,
            "settings_read"   =>true,
            "build_restart"   =>false,
            "build_create"    =>false,
            "build_cancel"    =>false,
            "log_view"        =>true
          },
          "id"              => repo.id,
          "name"            => "example-repo",
          "slug"            => "example-org/example-repo",
          "description"     => nil,
          "github_id"       => repo.github_id,
          "vcs_id"          => repo.vcs_id,
          "vcs_type"        => repo.vcs_type,
          "owner_name"      => "example-org",
          "vcs_name"        => "example-repo",
          "github_language" => nil,
          "active"          => false,
          "private"         => false,
          "server_type"     => 'git',
          "shared"          => false,
          "scan_failed_at"  => nil,
          "owner"           => { "@href"=> "/v3/org/#{org.id}" },
          "default_branch"  => {
            "@type"         => "branch",
            "@href"         => "/v3/repo/#{repo.id}/branch/master",
            "@representation"=> "minimal",
            "name"          => "master"},
          "starred"         => false,
          "managed_by_installation"=>false,
          "active_on_org"   => nil,
          "migration_status" => nil,
          "history_migration_status"  => nil,
          "config_validation" => false
        }]
      }}
    end

    describe 'it is not case sensitive' do
      let(:org_role_authorization) { { 'roles' => [] } }
      before  { get("/v3/owner/example-ORG")     }
      example { expect(last_response).to be_ok   }
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
        "github_id"        => 1234,
        "vcs_id"           => org.vcs_id,
        "vcs_type"         => org.vcs_type,
        "trial_allowed"    => false,
        "ro_mode"          => true,
        "avatar_url"       => nil,
        "education"        => false,
        "allow_migration"  => false,
        "allowance"        => {
          "@type"             => "allowance",
          "@representation"   => "minimal",
          "id"                => org.id
        },
        "custom_keys"      => []
      }}
    end

    describe "does not allow overriding org id" do
      let(:other) { Travis::API::V3::Models::Organization.new(login: 'other-org') }
      before      { other.save!                          }
      after       { other.delete                         }

      let(:org_role_authorization) { { 'roles' => [] } }
      let(:org_authorization) { { 'permissions' => [] } }

      before  { get("/v3/owner/example-org?organization.id=#{other.id}") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"          => "organization",
        "@href"          => "/v3/org/#{org.id}",
        "@representation"=> "standard",
        "@permissions"   => {
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
        "id"             => org.id,
        "login"          => "example-org",
        "name"           => nil,
        "github_id"      => 1234,
        "vcs_id"         => org.vcs_id,
        "vcs_type"       => org.vcs_type,
        "trial_allowed"  => false,
        "ro_mode"        => true,
        "avatar_url"     => nil,
        "education"      => false,
        "allow_migration"=> false,
        "allowance"      => {
          "@type"             => "allowance",
          "@representation"   => "minimal",
          "id"                => org.id
        },
        "custom_keys"    => [],
        "@warnings"      => [{
          "@type"        => "warning",
          "message"      => "query parameter organization.id not safelisted, ignored",
          "warning_type" => "ignored_parameter",
          "parameter"    => "organization.id"}]
      }}
    end
  end

  describe "user" do
    let(:user) { Travis::API::V3::Models::User.new(login: 'example-user', github_id: 5678) }
    before     { user.save!                      }
    after      { user.delete                     }

    describe 'existing user, public api, by login' do
      before  { get("/v3/owner/example-user")   }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"          => "user",
        "@href"          => "/v3/user/#{user.id}",
        "@representation"=> "standard",
        "@permissions"   => {"read" => true, "sync" => false},
        "id"             => user.id,
        "login"          => "example-user",
        "name"           => nil,
        "email"          => nil,
        "github_id"      => 5678,
        "vcs_id"         => user.vcs_id,
        "vcs_type"       => user.vcs_type,
        "avatar_url"     => nil,
        "is_syncing"     => nil,
        "synced_at"      => nil,
        "education"      => nil,
        "allow_migration"=> false,
        "allowance"      => {
          "@type"             => "allowance",
          "@representation"   => "minimal",
          "id"                => user.id
        },
        "custom_keys"    => [],
        "recently_signed_up"=>false,
        "secure_user_hash" => nil,
        "trial_allowed" => false,
        "internal" => false,
        "ro_mode" => false,
        "confirmed_at" => nil,
      }}
    end

    describe 'existing user, public api, by github_id' do
      before  { get("/v3/owner/github_id/5678")   }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"          => "user",
        "@href"          => "/v3/user/#{user.id}",
        "@representation"=> "standard",
        "@permissions"   => {"read" => true, "sync" => false},
        "id"             => user.id,
        "login"          => "example-user",
        "name"           => nil,
        "email"          => nil,
        "github_id"      => 5678,
        "vcs_id"         => user.vcs_id,
        "vcs_type"       => user.vcs_type,
        "avatar_url"     => nil,
        "education"      => nil,
        "is_syncing"     => nil,
        "synced_at"      => nil,
        "allow_migration"=> false,
        "allowance"      => {
          "@type"             => "allowance",
          "@representation"   => "minimal",
          "id"                => user.id
        },
        "custom_keys"    => [],
        "recently_signed_up"=>false,
        "secure_user_hash" => nil,
        "trial_allowed" => false,
        "internal" => false,
        "ro_mode" => false,
        "confirmed_at" => nil,
      }}
    end

    describe 'it is not case sensitive' do
      before  { get("/v3/owner/example-USER")   }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"            => "user",
        "@href"            => "/v3/user/#{user.id}",
        "@representation"  => "standard",
        "@permissions"     => {"read" => true, "sync" => false},
        "id"               => user.id,
        "login"            => "example-user",
        "name"             => nil,
        "email"            => nil,
        "github_id"        => 5678,
        "vcs_id"           => user.vcs_id,
        "vcs_type"         => user.vcs_type,
        "avatar_url"       => nil,
        "education"        => nil,
        "is_syncing"       => nil,
        "synced_at"        => nil,
        "allow_migration"  => false,
        "allowance"        => {
          "@type"             => "allowance",
          "@representation"   => "minimal",
          "id"                => user.id
        },
        "custom_keys"      => [],
        "recently_signed_up"=>false,
        "secure_user_hash" => nil,
        "trial_allowed" => false,
        "internal" => false,
        "ro_mode" => false,
        "confirmed_at" => nil,
      }}
    end

    describe "does not allow overriding user id" do
      let(:other) { Travis::API::V3::Models::User.new(login: 'other-user') }
      before      { other.save!                   }
      after       { other.delete                  }

      before  { get("/v3/owner/example-user?user.id=#{other.id}") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"            => "user",
        "@href"            => "/v3/user/#{user.id}",
        "@representation"  => "standard",
        "@permissions"     => {
          "read" => true,
          "sync" => false,
        },
        "id"               => user.id,
        "login"            => "example-user",
        "name"             => nil,
        "email"            => nil,
        "github_id"        => 5678,
        "vcs_id"           => user.vcs_id,
        "vcs_type"         => user.vcs_type,
        "avatar_url"       => nil,
        "education"        => nil,
        "is_syncing"       => nil,
        "synced_at"        => nil,
        "allow_migration"  => false,
        "allowance"        => {
          "@type"             => "allowance",
          "@representation"   => "minimal",
          "id"                => user.id
        },
        "custom_keys"      => [],
        "recently_signed_up"=>false,
        "secure_user_hash" => nil,
        "trial_allowed"    => false,
        "internal"         => false,
        "ro_mode"          => false,
        "confirmed_at" => nil,
        "@warnings"        => [{
          "@type"          => "warning",
          "message"        => "query parameter user.id not safelisted, ignored",
          "warning_type"   => "ignored_parameter",
          "parameter"      => "user.id"}]
      }}
    end
  end
end
