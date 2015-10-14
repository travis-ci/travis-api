require 'spec_helper'

describe Travis::API::V3::Services::Repositories::ForCurrentUser do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:jobs)  { Travis::API::V3::Models::Build.find(build.id).jobs }

  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)             }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                                    }}
  before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, push: true) }
  before        { repo.update_attribute(:private, true)                                         }
  after         { repo.update_attribute(:private, false)                                        }

  describe "private repository, private API, authenticated as user with access" do
    before  { get("/v3/repos", {}, headers)    }
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"                => "repositories",
      "@href"                => "/v3/repos",
      "@representation"      => "standard",
      "@pagination"          => {
        "limit"              => 100,
        "offset"             => 0,
        "count"              => 1,
        "is_first"           => true,
        "is_last"            => true,
        "next"               => nil,
        "prev"               => nil,
        "first"              => {
          "@href"            => "/v3/repos",
          "offset"           => 0,
          "limit"            => 100},
          "last"             => {
            "@href"          => "/v3/repos",
            "offset"         => 0,
            "limit"          => 100}},
      "repositories"         => [{
        "@type"              => "repository",
        "@href"              => "/v3/repo/#{repo.id}",
        "@representation"    => "standard",
        "@permissions"       => {
          "read"             => true,
          "enable"           => true,
          "disable"          => true,
          "create_request"   => true},
        "id"                 =>  repo.id,
        "name"               =>  "minimal",
        "slug"               =>  "svenfuchs/minimal",
        "description"        => nil,
        "github_language"    => nil,
        "active"             => true,
        "private"            => true,
        "owner"              => {
          "@type"            => "user",
          "@href"            => "/v3/user/#{repo.owner_id}",
          "id"               => repo.owner_id,
          "login"            => "svenfuchs" },
        "default_branch"     => {
          "@type"            => "branch",
          "@href"            => "/v3/repo/#{repo.id}/branch/master",
          "@representation"  => "minimal",
          "name"             => "master"}}]
    }}
  end

  describe "don't nest list of repositories inside a list of repositories even if the user asks for it. user has no idea what they are doing" do
    before  { get("/v3/repos?include=user.repositories", {}, headers)                          }
    example { expect(last_response).to be_ok                                                   }
    example { expect(JSON.load(body)['repositories'].first['owner']['repositories']).to be_nil }
  end

  describe "filter: private=false" do
    before  { get("/v3/repos", {"repository.private" => "false"}, headers)                           }
    example { expect(last_response)                   .to be_ok                                      }
    example { expect(JSON.load(body)['repositories']) .to be == []                                   }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/repos?repository.private=false" }
  end

  describe "filter: active=false" do
    before  { get("/v3/repos", {"repository.active" => "false"}, headers)  }
    example { expect(last_response)                   .to be_ok            }
    example { expect(JSON.load(body)['repositories']) .to be == []         }
  end
end
