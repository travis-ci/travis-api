require 'spec_helper'

describe Travis::API::V3::Services::Owner::Repositories do
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }

  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
  before        { Permission.create(repository: repo, user: repo.owner, pull: true) }
  before        { repo.update_attribute(:private, true)                             }
  after         { repo.update_attribute(:private, false)                            }

  describe "private repository, private API, authenticated as user with access" do
    before  { get("/v3/owner/svenfuchs/repos", {}, headers)    }
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"             => "repositories",
      "@href"             => "/v3/owner/svenfuchs/repos",
      "repositories"      => [{
        "@type"           => "repository",
        "@href"           => "/v3/repo/#{repo.id}",
        "@permissions"    => {
          "read"          => true,
          "enable"        => false,
          "disable"       => false,
          "create_request"=> false},
        "id"              =>  repo.id,
        "name"            =>  "minimal",
        "slug"            =>  "svenfuchs/minimal",
        "description"     => nil,
        "github_language" => nil,
        "active"          => true,
        "private"         => true,
        "owner"           => {
          "@type"         => "user",
          "@href"         => "/v3/user/#{repo.owner_id}",
          "id"            => repo.owner_id,
          "login"         => "svenfuchs" },
        "last_build"      => {
          "@type"         => "build",
          "@href"         => "/v3/build/#{repo.last_build_id}",
          "id"            => repo.last_build_id,
          "number"        => "2",
          "state"         => "passed",
          "duration"      => nil,
          "started_at"    => "2010-11-12T12:30:00Z",
          "finished_at"   => "2010-11-12T12:30:20Z"},
        "default_branch"  => {
          "@type"         => "branch",
          "@href"         => "/v3/repo/#{repo.id}/branch/master",
          "name"          => "master",
          "last_build"    => {
            "@type"       => "build",
            "@href"       => "/v3/build/#{repo.last_build.id}",
            "id"          => repo.last_build.id,
            "number"      => "3",
            "state"       => "configured",
            "duration"    => nil,
            "event_type"  => "push",
            "started_at"  => "2010-11-12T13:00:00Z",
            "finished_at" => nil}}}]
    }}
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