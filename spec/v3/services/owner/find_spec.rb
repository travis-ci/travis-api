describe Travis::API::V3::Services::Owner::Find, set_app: true do
  describe "organization" do
    let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org', github_id: 1234) }
    before    { org.save!                              }
    after     { org.delete                             }

    describe 'existing org, public api, by login' do
      before  { get("/v3/owner/example-org")     }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"            => "organization",
        "@href"            => "/v3/org/#{org.id}",
        "@representation"  => "standard",
        "@permissions"     => { "read"=>true, "sync"=>false },
        "id"               => org.id,
        "login"            => "example-org",
        "name"             => nil,
        "github_id"        => 1234,
        "avatar_url"       => nil
      }}
    end

    describe 'existing org, public api, by github_id' do
      before  { get("/v3/owner/github_id/1234")     }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"            => "organization",
        "@href"            => "/v3/org/#{org.id}",
        "@representation"  => "standard",
        "@permissions"     => { "read"=>true, "sync"=>false },
        "id"               => org.id,
        "login"            => "example-org",
        "name"             => nil,
        "github_id"        => 1234,
        "avatar_url"       => nil
      }}
    end

    describe 'eager loading repositories via organization.repositories' do
      let(:repo) { Travis::API::V3::Models::Repository.new(name: 'example-repo', owner_name: 'example-org', owner_id: org.id, owner_type: 'Organization')}

      before { repo.save!   }
      after  { repo.destroy }

      before  { get("/v3/owner/example-org?include=organization.repositories,user.repositories") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"               => "organization",
        "@href"               => "/v3/org/#{org.id}",
        "@representation"     => "standard",
        "@permissions"        => { "read"=>true, "sync"=>false },
        "id"                  => org.id,
        "login"               => "example-org",
        "name"                => nil,
        "github_id"           => 1234,
        "avatar_url"          => nil,
        "repositories"        => [{
          "@type"             => "repository",
          "@href"             => "/v3/repo/#{repo.id}",
          "@representation"   => "standard",
          "@permissions"      => {
            "read"            => true,
            "activate"        => false,
            "deactivate"      => false,
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
          "github_language"   => nil,
          "active"            => false,
          "private"           => false,
          "owner"             => { "@href"=> "/v3/org/#{org.id}" },
          "default_branch"    => {
            "@type"           => "branch",
            "@href"           => "/v3/repo/#{repo.id}/branch/master",
            "@representation" => "minimal",
            "name"            => "master"},
          "starred"           => false
        }]
      }}
    end

    describe 'eager loading repositories via owner.repositories' do
      let(:repo) { Travis::API::V3::Models::Repository.new(name: 'example-repo', owner_name: 'example-org', owner_id: org.id, owner_type: 'Organization')}

      before { repo.save!   }
      after  { repo.destroy }

      before  { get("/v3/owner/example-org?include=owner.repositories") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"             => "organization",
        "@href"             => "/v3/org/#{org.id}",
        "@representation"   => "standard",
        "@permissions"      => { "read"=>true, "sync"=>false },
        "id"                => org.id,
        "login"             => "example-org",
        "name"              => nil,
        "github_id"         => 1234,
        "avatar_url"        => nil,
        "repositories"      => [{
          "@type"           => "repository",
          "@href"           => "/v3/repo/#{repo.id}",
          "@representation" => "standard",
          "@permissions"    => {
            "read"          => true,
            "activate"      => false,
            "deactivate"    => false,
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
          "github_language" => nil,
          "active"          => false,
          "private"         => false,
          "owner"           => { "@href"=> "/v3/org/#{org.id}" },
          "default_branch"  => {
            "@type"         => "branch",
            "@href"         => "/v3/repo/#{repo.id}/branch/master",
            "@representation"=> "minimal",
            "name"          => "master"},
          "starred"         => false
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
        "@permissions"     => { "read"=>true, "sync"=>false },
        "id"               => org.id,
        "login"            => "example-org",
        "name"             => nil,
        "github_id"        => 1234,
        "avatar_url"       => nil
      }}
    end

    describe "does not allow overriding org id" do
      let(:other) { Travis::API::V3::Models::Organization.new(login: 'other-org') }
      before      { other.save!                          }
      after       { other.delete                         }

      before  { get("/v3/owner/example-org?organization.id=#{other.id}") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"          => "organization",
        "@href"          => "/v3/org/#{org.id}",
        "@representation"=> "standard",
        "@permissions"   => { "read"=>true, "sync"=>false },
        "id"             => org.id,
        "login"          => "example-org",
        "name"           => nil,
        "github_id"      => 1234,
        "avatar_url"     => nil,
        "@warnings"      => [{
          "@type"        => "warning",
          "message"      => "query parameter organization.id not safelisted, ignored",
          "warning_type" => "ignored_parameter",
          "parameter"    => "organization.id"}]
      }}
    end

    describe "authenticated as user with access on .com and has an org with a subscription" do
      let(:user) { Travis::API::V3::Models::User.create(login: 'example-user', github_id: 5678) }
      let(:valid_to) { Time.now.utc + 1.month }
      let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
      let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                  }}
      let!(:subscription) { Travis::API::V3::Models::Subscription.create(owner: org, valid_to: valid_to,source: "stripe", status: "subscribed", selected_plan: "travis-ci-two-builds") }
      before  { get("/v3/owner/example-org?include=owner.subscription", {}, headers) }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be ==        {
        "@type"            => "organization",
        "@href"            => "/v3/org/#{org.id}",
        "@representation"  => "standard",
        "@permissions"     => {"read"=>true, "sync"=>false},
        "id"               => org.id,
        "login"            => org.login,
        "name"             => org.name,
        "github_id"        => org.github_id,
        "avatar_url"       => nil,
        "subscription"     => {
          "@type"          => "subscription",
          "@href"          => "/v3/subscription/#{subscription.id}",
          "@representation"=> "standard",
          "id"             => subscription.id,
          "valid_to"       => subscription.valid_to.strftime('%Y-%m-%dT%H:%M:%SZ'),
          "first_name"     => nil,
          "last_name"      => nil,
          "company"        => nil,
          "zip_code"       => nil,
          "address"        => nil,
          "address2"       => nil,
          "city"           => nil,
          "state"          => nil,
          "country"        => nil,
          "vat_id"         => nil,
          "status"         => "subscribed",
          "source"         => "stripe",
          "selected_plan"  => "travis-ci-two-builds" }
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
        "@permissions"   => {"read"=>true, "sync"=>false},
        "id"             => user.id,
        "login"          => "example-user",
        "name"           => nil,
        "github_id"      => 5678,
        "avatar_url"     => nil,
        "is_syncing"     => nil,
        "synced_at"      => nil
      }}
    end

    describe 'existing user, public api, by github_id' do
      before  { get("/v3/owner/github_id/5678")   }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"          => "user",
        "@href"          => "/v3/user/#{user.id}",
        "@representation"=> "standard",
        "@permissions"   => {"read"=>true, "sync"=>false},
        "id"             => user.id,
        "login"          => "example-user",
        "name"           => nil,
        "github_id"      => 5678,
        "avatar_url"     => nil,
        "is_syncing"     => nil,
        "synced_at"      => nil
      }}
    end

    describe 'it is not case sensitive' do
      before  { get("/v3/owner/example-USER")   }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"            => "user",
        "@href"            => "/v3/user/#{user.id}",
        "@representation"  => "standard",
        "@permissions"     => {"read"=>true, "sync"=>false},
        "id"               => user.id,
        "login"            => "example-user",
        "name"             => nil,
        "github_id"        => 5678,
        "avatar_url"       => nil,
        "is_syncing"       => nil,
        "synced_at"        => nil
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
        "@permissions"     => {"read"=>true, "sync"=>false},
        "id"               => user.id,
        "login"            => "example-user",
        "name"             => nil,
        "github_id"        => 5678,
        "avatar_url"       => nil,
        "is_syncing"       => nil,
        "synced_at"        => nil,
        "@warnings"        => [{
          "@type"          => "warning",
          "message"        => "query parameter user.id not safelisted, ignored",
          "warning_type"   => "ignored_parameter",
          "parameter"      => "user.id"}]
      }}
    end

    describe "authenticated as user with access on .com and has a subscription" do
      let(:valid_to) { Time.now.utc + 1.month }
      let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
      let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                  }}
      let!(:subscription) { Travis::API::V3::Models::Subscription.create(owner: user, valid_to: valid_to,source: "stripe", status: "subscribed", selected_plan: "travis-ci-two-builds") }
      before  { get("/v3/owner/example-user?include=owner.subscription", {}, headers) }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be ==        {
        "@type"            => "user",
        "@href"            => "/v3/user/#{user.id}",
        "@representation"  => "standard",
        "@permissions"     => {"read"=>true, "sync"=>true},
        "id"               => user.id,
        "login"            => user.login,
        "name"             => user.name,
        "github_id"        => user.github_id,
        "avatar_url"       => nil,
        "is_syncing"       => user.is_syncing,
        "synced_at"        => user.synced_at,
        "is_syncing"       => nil,
        "synced_at"        => nil,
        "subscription"     => {
          "@type"          => "subscription",
          "@href"          => "/v3/subscription/#{subscription.id}",
          "@representation"=> "standard",
          "id"             => subscription.id,
          "valid_to"       => subscription.valid_to.strftime('%Y-%m-%dT%H:%M:%SZ'),
          "first_name"     => nil,
          "last_name"      => nil,
          "company"        => nil,
          "zip_code"       => nil,
          "address"        => nil,
          "address2"       => nil,
          "city"           => nil,
          "state"          => nil,
          "country"        => nil,
          "vat_id"         => nil,
          "status"         => "subscribed",
          "source"         => "stripe",
          "selected_plan"  => "travis-ci-two-builds" }
      }}
    end
  end
end
