require 'spec_helper'

describe Travis::API::V3::Services::Account::Find do
  describe "organization" do
    let(:org) { Organization.new(login: 'example-org') }
    before    { org.save!                              }
    after     { org.delete                             }

    describe 'existing org, public api' do
      before  { get("/v3/account/example-org")   }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"      => "organization",
        "@href"      => "/v3/org/#{org.id}",
        "id"         => org.id,
        "login"      => "example-org",
        "name"       => nil,
        "github_id"  => nil,
        "avatar_url" => nil
      }}
    end

    describe 'it is not case sensitive' do
      before  { get("/v3/account/example-ORG")   }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"      => "organization",
        "@href"      => "/v3/org/#{org.id}",
        "id"         => org.id,
        "login"      => "example-org",
        "name"       => nil,
        "github_id"  => nil,
        "avatar_url" => nil
      }}
    end

    describe "does not allow overriding org id" do
      let(:other) { Organization.new(login: 'other-org') }
      before      { other.save!                          }
      after       { other.delete                         }

      before  { get("/v3/account/example-org?organization.id=#{other.id}") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"      => "organization",
        "@href"      => "/v3/org/#{org.id}",
        "id"         => org.id,
        "login"      => "example-org",
        "name"       => nil,
        "github_id"  => nil,
        "avatar_url" => nil
      }}
    end
  end

  describe "user" do
    let(:user) { User.new(login: 'example-user') }
    before     { user.save!                      }
    after      { user.delete                     }

    describe 'existing user, public api' do
      before  { get("/v3/account/example-user")   }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"      => "user",
        "@href"      => "/v3/user/#{user.id}",
        "id"         => user.id,
        "login"      => "example-user",
        "name"       => nil,
        "github_id"  => nil,
        "avatar_url" => nil,
        "is_syncing" => nil,
        "synced_at"  => nil
      }}
    end

    describe 'it is not case sensitive' do
      before  { get("/v3/account/example-USER")   }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"      => "user",
        "@href"      => "/v3/user/#{user.id}",
        "id"         => user.id,
        "login"      => "example-user",
        "name"       => nil,
        "github_id"  => nil,
        "avatar_url" => nil,
        "is_syncing" => nil,
        "synced_at"  => nil
      }}
    end

    describe "does not allow overriding user id" do
      let(:other) { User.new(login: 'other-user') }
      before      { other.save!                   }
      after       { other.delete                  }

      before  { get("/v3/account/example-user?user.id=#{other.id}") }
      example { expect(last_response).to be_ok   }
      example { expect(JSON.load(body)).to be == {
        "@type"      => "user",
        "@href"      => "/v3/user/#{user.id}",
        "id"         => user.id,
        "login"      => "example-user",
        "name"       => nil,
        "github_id"  => nil,
        "avatar_url" => nil,
        "is_syncing" => nil,
        "synced_at"  => nil
      }}
    end
  end
end
