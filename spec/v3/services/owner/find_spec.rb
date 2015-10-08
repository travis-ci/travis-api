require 'spec_helper'

describe Travis::API::V3::Services::Owner::Find do
  describe "organization" do
    let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org') }
    before    { org.save!                              }
    after     { org.delete                             }

    describe 'existing org, public api' do
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
        "github_id"        => nil,
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
        "github_id"           => nil,
        "avatar_url"          => nil,
        "repositories"        => [{
          "@type"             => "repository",
          "@href"             => "/v3/repo/#{repo.id}",
          "@representation"   => "standard",
          "@permissions"      => {
            "read"            => true,
            "enable"          => false,
            "disable"         => false,
            "create_request"  => false},
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
            "name"            => "master"}
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
        "github_id"         => nil,
        "avatar_url"        => nil,
        "repositories"      => [{
          "@type"           => "repository",
          "@href"           => "/v3/repo/#{repo.id}",
          "@representation" => "standard",
          "@permissions"    => {
            "read"          => true,
            "enable"        => false,
            "disable"       => false,
            "create_request"=> false},
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
            "name"           => "master"}
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
        "github_id"        => nil,
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
        "github_id"      => nil,
        "avatar_url"     => nil,
        "@warnings"      => [{
          "@type"        => "warning",
          "message"      => "query parameter organization.id not whitelisted, ignored",
          "warning_type" => "ignored_parameter",
          "parameter"    => "organization.id"}]
      }}
    end
  end

  describe "user" do
    let(:user) { Travis::API::V3::Models::User.new(login: 'example-user') }
    before     { user.save!                      }
    after      { user.delete                     }

    describe 'existing user, public api' do
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
        "github_id"      => nil,
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
        "github_id"        => nil,
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
        "github_id"        => nil,
        "avatar_url"       => nil,
        "is_syncing"       => nil,
        "synced_at"        => nil,
        "@warnings"        => [{
          "@type"          => "warning",
          "message"        => "query parameter user.id not whitelisted, ignored",
          "warning_type"   => "ignored_parameter",
          "parameter"      => "user.id"}]
      }}
    end
  end
end
