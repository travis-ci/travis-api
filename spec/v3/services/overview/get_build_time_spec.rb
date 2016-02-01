require 'spec_helper'

describe Travis::API::V3::Services::Overview::GetBuildTime do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  describe "fetching steak data on a public repository" do
    before     { get("/v3/repo/#{repo.id}/overview/build_time")   }
    example    { expect(last_response).to be_ok }
  end

  describe "fetching streak from non-existing repo" do
    before     { get("/v3/repo/1231987129387218/overview/build_time")  }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "build_time on public repository" do
    before     {
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end
      Travis::API::V3::Models::Build.create(repository_id: repo.id, id: 345, created_at: DateTime.now - 5, duration: 600, state: 'passed', branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, id: 346, created_at: DateTime.now - 4, duration: 1200, state: 'failed', branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, id: 347, created_at: DateTime.now - 2, duration: 10, state: 'passed', branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, id: 348, created_at: DateTime.now    , duration: 6000, state: 'failed', branch_name: repo.default_branch.name)

      get("/v3/repo/#{repo.id}/overview/build_time") }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
      "@type" => "overview",
      "@href" => "/v3/repo/#{repo.id}/overview/build_time",
      "@representation" => "standard",
      "build_time" => [
        { "id" => 345,
          "state" => "passed",
          "duration" => 600
        },
        { "id" => 346,
          "state" => "failed",
          "duration" => 1200
        },
        { "id" => 347,
          "state" => "passed",
          "duration" => 10
        },
        { "id" => 348,
          "state" => "failed",
          "duration" => 6000
        }
      ]
    }}
  end


  describe "build_time on public empty repository" do
    before     {
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end
      get("/v3/repo/#{repo.id}/overview/build_time") }
    example    { expect(last_response).to be_ok                    }
    example    { expect(parsed_body).to be == {
      "@type" => "overview",
      "@href" => "/v3/repo/#{repo.id}/overview/build_time",
      "@representation" => "standard",
      "build_time" => []
    }}
  end


  describe "private repository, not authenticated" do
    before  { repo.update_attribute(:private, true)             }
    before  { get("/v3/repo/#{repo.id}/overview/build_time") }
    before  { repo.update_attribute(:private, false)            }
    example { expect(last_response).to be_not_found             }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "private repository, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"}                        }
    before        { Travis::API::V3::Models::Build.where(repository_id: repo).each do |build| build.destroy end
                    Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}/overview/build_time", {}, headers)    }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(parsed_body).to be == {
      "@type" => "overview",
      "@href" => "/v3/repo/#{repo.id}/overview/build_time",
      "@representation" => "standard",
      "build_time" => []
    }}
  end
end
