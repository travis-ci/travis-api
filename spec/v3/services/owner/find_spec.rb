describe Travis::API::V3::Services::Owner::Find, set_app: true do

  describe "organization" do
    let(:org) { Factory(:org_v3, login: 'example-org', github_id: 1234) }

    before    { org.save! }
    after     { org.delete                             }

    describe 'existing org, public api, by login' do
      before  { get("/v3/owner/example-org")     }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"            => "organization",
        "@href"            => "/v3/org/#{org.id}",
        "@representation"  => "standard",
        "@permissions"     => { "read" => true, "sync" => false, "admin" => false },
        "id"               => org.id,
        "login"            => "example-org",
        "name"             => "travis-ci",
        "github_id"        => 1234,
        "vcs_id"           => 1234,
        "vcs_type"         => 'GithubOrganization',
        "avatar_url"       => nil,
        "education"        => false,
        "allow_migration"  => false,
      }}
    end

    describe 'existing org, public api, by github_id' do
      before  { get("/v3/owner/github_id/1234")     }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"            => "organization",
        "@href"            => "/v3/org/#{org.id}",
        "@representation"  => "standard",
        "@permissions"     => { "read" => true, "sync" => false, "admin" => false },
        "id"               => org.id,
        "login"            => "example-org",
        "name"             => "travis-ci",
        "github_id"        => 1234,
        "vcs_id"           => 1234,
        "vcs_type"         => 'GithubOrganization',
        "avatar_url"       => nil,
        "education"        => false,
        "allow_migration"  => false,
      }}
    end

    describe 'eager loading repositories via organization.repositories' do
      let(:repo) { Factory(:repo_v3, name: 'example-repo', owner_name: 'example-org', owner_id: org.id, owner_type: 'Organization')}

      before { repo.save!   }
      after  { repo.destroy }

      before  { get("/v3/owner/example-org?include=organization.repositories,user.repositories") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"               => "organization",
        "@href"               => "/v3/org/#{org.id}",
        "@representation"     => "standard",
        "@permissions"        => { "read" => true, "sync" => false, "admin" => false },
        "id"                  => org.id,
        "login"               => "example-org",
        "name"                => "travis-ci",
        "github_id"           => 1234,
        "vcs_id"              => 1234,
        "vcs_type"            => 'GithubOrganization',
        "avatar_url"          => nil,
        "education"           => false,
        "allow_migration"     => false,
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
            "admin"           => false
          },
          "id"                => repo.id,
          "name"              => "example-repo",
          "slug"              => "example-org/example-repo",
          "description"       => nil,
          "github_id"         => repo.github_id,
          "vcs_id"            => repo.vcs_id,
          "vcs_type"          => "GithubRepository",
          "github_language"   => nil,
          "active"            => true,
          "private"           => false,
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
          "history_migration_status"  => nil
        }]
      }}
    end

    describe 'eager loading repositories via owner.repositories' do
      let(:repo) { Factory(:repo_v3, name: 'example-repo', owner_name: 'example-org', owner_id: org.id, owner_type: 'Organization')}

      before { repo.save!   }
      after  { repo.destroy }

      before  { get("/v3/owner/example-org?include=owner.repositories") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"             => "organization",
        "@href"             => "/v3/org/#{org.id}",
        "@representation"   => "standard",
        "@permissions"      => { "read" => true, "sync" => false, "admin" => false },
        "id"                => org.id,
        "login"             => "example-org",
        "name"              => "travis-ci",
        "github_id"         => 1234,
        "vcs_id"            => 1234,
        "vcs_type"          => 'GithubOrganization',
        "avatar_url"        => nil,
        "education"         => false,
        "allow_migration"   => false,
        "repositories"      => [{
          "@type"           => "repository",
          "@href"           => "/v3/repo/#{repo.id}",
          "@representation" => "standard",
          "@permissions"    => {
            "read"          => true,
            "activate"      => false,
            "deactivate"    => false,
            "migrate"       => false,
            "star"          => false,
            "unstar"        => false,
            "create_request"=> false,
            "create_cron"   => false,
            "create_env_var"  => false,
            "create_key_pair" => false,
            "delete_key_pair" => false,
            "admin"         => false
          },
          "id"              => repo.id,
          "name"            => "example-repo",
          "slug"            => "example-org/example-repo",
          "description"     => nil,
          "github_id"       => repo.github_id,
          "vcs_id"          => repo.vcs_id,
          "vcs_type"        => "GithubRepository",
          "github_language" => nil,
          "active"          => true,
          "private"         => false,
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
          "history_migration_status"  => nil
        }]
      }}
    end

    describe 'it is not case sensitive' do
      before  { get("/v3/owner/example-ORG")     }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"            => "organization",
        "@href"            => "/v3/org/#{org.id}",
        "@representation"  => "standard",
        "@permissions"     => { "read" => true, "sync" => false, "admin" => false },
        "id"               => org.id,
        "login"            => "example-org",
        "name"             => "travis-ci",
        "github_id"        => 1234,
        "vcs_id"           => 1234,
        "vcs_type"         => 'GithubOrganization',
        "avatar_url"       => nil,
        "education"        => false,
        "allow_migration"  => false,
      }}
    end

    describe "does not allow overriding org id" do
      let(:other) { Factory(:org_v3, login: 'other-org') }
      before      { other.save!                          }
      after       { other.delete                         }

      before  { get("/v3/owner/example-org?organization.id=#{other.id}") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"          => "organization",
        "@href"          => "/v3/org/#{org.id}",
        "@representation"=> "standard",
        "@permissions"   => { "read" => true, "sync" => false, "admin" => false },
        "id"             => org.id,
        "login"          => "example-org",
        "name"           => "travis-ci",
        "github_id"      => 1234,
        "vcs_id"         => 1234,
        "vcs_type"       => 'GithubOrganization',
        "avatar_url"     => nil,
        "education"      => false,
        "allow_migration"=> false,
        "@warnings"      => [{
          "@type"        => "warning",
          "message"      => "query parameter organization.id not safelisted, ignored",
          "warning_type" => "ignored_parameter",
          "parameter"    => "organization.id"}]
      }}
    end
  end

  describe "user" do
    let(:user) { Factory(:user, login: 'example-user', github_id: 5678) }
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
        "name"           => user.name,
        "github_id"      => 5678,
        "vcs_id"         => 5678,
        "vcs_type"       => 'GithubUser',
        "avatar_url"     => user.avatar_url,
        "is_syncing"     => nil,
        "synced_at"      => nil,
        "education"      => nil,
        "allow_migration"=> false,
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
        "name"           => user.name,
        "github_id"      => 5678,
        "vcs_id"         => 5678,
        "vcs_type"       => 'GithubUser',
        "avatar_url"     => user.avatar_url,
        "education"      => nil,
        "is_syncing"     => nil,
        "synced_at"      => nil,
        "allow_migration"=> false,
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
        "name"             => user.name,
        "github_id"        => 5678,
        "vcs_id"           => 5678,
        "vcs_type"         => 'GithubUser',
        "avatar_url"       => user.avatar_url,
        "education"        => nil,
        "is_syncing"       => nil,
        "synced_at"        => nil,
        "allow_migration"  => false,
      }}
    end

    describe "does not allow overriding user id" do
      let(:other) { Factory(:user, login: 'other-user') }
      before      { other.save!                   }
      after       { other.delete                  }

      before  { get("/v3/owner/example-user?user.id=#{other.id}") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"            => "user",
        "@href"            => "/v3/user/#{user.id}",
        "@representation"  => "standard",
        "@permissions"     => {"read" => true, "sync" => false},
        "id"               => user.id,
        "login"            => "example-user",
        "name"             => user.name,
        "github_id"        => 5678,
        "vcs_id"           => 5678,
        "vcs_type"         => 'GithubUser',
        "avatar_url"       => user.avatar_url,
        "education"        => nil,
        "is_syncing"       => nil,
        "synced_at"        => nil,
        "allow_migration"  => false,
        "@warnings"        => [{
          "@type"          => "warning",
          "message"        => "query parameter user.id not safelisted, ignored",
          "warning_type"   => "ignored_parameter",
          "parameter"      => "user.id"}]
      }}
    end
  end
end
