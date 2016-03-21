require 'spec_helper'

describe Travis::API::V3::Services::Repositories::ForOwner do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:jobs)  { Travis::API::V3::Models::Build.find(build.id).jobs }

  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
  before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
  before        { repo.update_attribute(:private, true)                             }
  after         { repo.update_attribute(:private, false)                            }


  describe "private repository, private API, authenticated as user with access" do
    before  { get("/v3/owner/svenfuchs/repos", {}, headers) }
    example { expect(last_response).to be_ok }
    example { expect(JSON.load(body)).to be == {
      "@type"                => "repositories",
      "@href"                => "/v3/owner/svenfuchs/repos",
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
          "@href"            => "/v3/owner/svenfuchs/repos",
          "offset"           => 0,
          "limit"            => 100},
          "last"             => {
            "@href"          => "/v3/owner/svenfuchs/repos",
            "offset"         => 0,
            "limit"          => 100}},
      "repositories"         => [{
        "@type"              => "repository",
        "@href"              => "/v3/repo/#{repo.id}",
        "@representation"    => "standard",
        "@permissions"       => {
          "read"             => true,
          "enable"           => false,
          "disable"          => false,
          "star"             => false,
          "unstar"           => false,
          "create_request"   => false,
          "create_cron"      => false},
        "id"                 => repo.id,
        "name"               => "minimal",
        "slug"               => "svenfuchs/minimal",
        "description"        => nil,
        "github_language"    => nil,
        "active"             => true,
        "private"            => true,
        "owner"              => {
          "@type"            => "user",
          "id"               => repo.owner_id,
          "login"            => "svenfuchs",
          "@href"            => "/v3/user/#{repo.owner_id}" },
        "default_branch"     => {
          "@type"            => "branch",
          "@href"            => "/v3/repo/#{repo.id}/branch/master",
          "@representation"  => "minimal",
          "name"             => "master"},
          "starred"          => false
        }]}}
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

  describe "filter: starred=true" do
    before  { Travis::API::V3::Models::Star.create(user: repo.owner, repository: repo)   }
    before  { get("/v3/repos", {"starred" => "true"}, headers)                           }
    after   { repo.owner.stars.each(&:destroy)                                           }
    example { expect(last_response)                   .to be_ok                          }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/repos?starred=true" }
    example { expect(JSON.load(body)['repositories']) .not_to be_empty                   }
  end

  describe "filter: starred=false" do
    before  { get("/v3/repos", {"starred" => "false"}, headers)                              }
    example { expect(last_response)                   .to be_ok                              }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/repos?starred=false"    }
    example { expect(JSON.load(body)['repositories']) .not_to be_empty                       }
  end

  describe "filter: starred=false but no unstarred repos" do
    before  { Travis::API::V3::Models::Star.create(user: repo.owner, repository: repo)       }
    after   { repo.owner.stars.each(&:destroy)                                               }
    before  { get("/v3/repos", {"starred" => "false"}, headers)                              }
    example { expect(last_response)                   .to be_ok                              }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/repos?starred=false"    }
    example { expect(JSON.load(body)['repositories']) .to be_empty                           }
  end

  describe "sorting by default_branch.last_build" do
    let(:repo2)  { Travis::API::V3::Models::Repository.create(owner_name: 'svenfuchs', name: 'maximal', owner_id: 1, owner_type: "User", last_build_state: "passed", active: true, last_build_id: 1788, next_build_number: 3) }
    before  { repo2.save! }
    before  { get("/v3/owner/svenfuchs/repos?sort_by=default_branch.last_build", {}, headers) }
    example { expect(last_response).to be_ok }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/owner/svenfuchs/repos?sort_by=default_branch.last_build" }
    example { expect(JSON.load(body)['repositories'])   .to be == [{
        "@type"           => "repository",
        "@href"           => "/v3/repo/1",
        "@representation" => "standard",
        "@permissions"    => {
          "read"          => true,
          "enable"        => false,
          "disable"       => false,
          "star"          => false,
          "unstar"        => false,
          "create_request"=> false },
        "id"              => 1,
        "name"            => "minimal",
        "slug"            => "svenfuchs/minimal",
        "description"     => nil,
        "github_language" => nil,
        "active"          => true,
        "private"         => true,
        "owner"           => {
          "@type"         => "user",
          "id"            => 1,
          "login"         => "svenfuchs",
          "@href"         => "/v3/user/1" },
        "default_branch"  => {
          "@type"         => "branch",
          "@href"         => "/v3/repo/1/branch/master",
          "@representation"=>"minimal",
          "name"          => "master" },
        "starred"         => false }, {
        "@type"           => "repository",
        "@href"           => "/v3/repo/#{repo2.id}",
        "@representation" => "standard",
        "@permissions"    => {
          "read"          => true,
          "enable"        => false,
          "disable"       => false,
          "star"          => false,
          "unstar"        => false,
          "create_request"=> false },
        "id"              => repo2.id,
        "name"            => "maximal",
        "slug"            => "svenfuchs/maximal",
        "description"     => nil,
        "github_language" => nil,
        "active"          => true,
        "private"         => false,
        "owner"           => {
          "@type"         => "user",
          "id"            => 1,
          "login"         => "svenfuchs",
          "@href"         => "/v3/user/1" },
        "default_branch"  => {
          "@type"         => "branch",
          "@href"         => "/v3/repo/#{repo2.id}/branch/master",
          "@representation"=>"minimal",
          "name"           =>"master" },
          "starred"=>false}]}
  end
end
