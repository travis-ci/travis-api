require 'spec_helper'

describe Travis::API::V3::Services::Overview::BuildDuration do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  describe "fetching build_duration data on a public repository" do
    before  { get("/v3/repo/#{repo.id}/overview/build_duration")  }
    example { expect(last_response).to be_ok                      }
  end

  describe "fetching build_duration from non-existing repo" do
    before  { get("/v3/repo/1231987129387218/overview/build_duration") }
    example { expect(last_response).to be_not_found                    }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "build_duration on public repository" do
    builds = []
    before  {
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end
      builds.push Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 5, duration: 600,  number: 1, state: 'passed',   branch_name: repo.default_branch.name)
      builds.push Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 4, duration: 1200, number: 2, state: 'failed',   branch_name: repo.default_branch.name)
      builds.push Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 2, duration: 10,   number: 3, state: 'passed',   branch_name: repo.default_branch.name)
      builds.push Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 1, duration: 0,    number: 4, state: 'canceled', branch_name: repo.default_branch.name)
      builds.push Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now,     duration: 6000, number: 4, state: 'failed',   branch_name: repo.default_branch.name)
      get("/v3/repo/#{repo.id}/overview/build_duration") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/build_duration",
      "@representation" => "standard",
      "build_duration"  => [
        { "@type"           => "build",
          "@href"           => "/v3/build/#{builds[-1].id}",
          "@representation" => "minimal",
          "id"              => builds[-1].id,
          "number"          => "4",
          "state"           => "failed",
          "duration"        => 6000,
          "event_type"      => nil,
          "previous_state"  => nil,
          "started_at"      => nil,
          "finished_at"     => nil
        },
        { "@type"           => "build",
          "@href"           => "/v3/build/#{builds[-3].id}",
          "@representation" => "minimal",
          "id"              => builds[-3].id,
          "number"          => "3",
          "state"           => "passed",
          "duration"        => 10,
          "event_type"      => nil,
          "previous_state"  => nil,
          "started_at"      => nil,
          "finished_at"     => nil
        },
        { "@type"           => "build",
          "@href"           => "/v3/build/#{builds[-4].id}",
          "@representation" => "minimal",
          "id"              => builds[-4].id,
          "number"          => "2",
          "state"           => "failed",
          "duration"        => 1200,
          "event_type"      => nil,
          "previous_state"  => nil,
          "started_at"      => nil,
          "finished_at"     => nil
        },
        { "@type"           => "build",
          "@href"           => "/v3/build/#{builds[-5].id}",
          "@representation" => "minimal",
          "id"              => builds[-5].id,
          "number"          => "1",
          "state"           => "passed",
          "duration"        => 600,
          "event_type"      => nil,
          "previous_state"  => nil,
          "started_at"      => nil,
          "finished_at"     => nil
        }
      ]
    }}
  end

  describe "build_duration returns last 20 builds" do
    builds_result = []
    before  {
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end
      builds = []
      for i in 1..21
        builds.push Travis::API::V3::Models::Build.create(repository_id: repo.id, duration: 1,  number: i, state: 'passed', branch_name: repo.default_branch.name)
      end
      builds_result = []
      for j in 1..20
        builds_result.push({
          "@type"           => "build",
          "@href"           => "/v3/build/#{builds[-j].id}",
          "@representation" => "minimal",
          "id"              => builds[-j].id,
          "number"          => (22-j).to_s,
          "state"           => "passed",
          "duration"        => 1,
          "event_type"      => nil,
          "previous_state"  => nil,
          "started_at"      => nil,
          "finished_at"     => nil
        })
      end
      get("/v3/repo/#{repo.id}/overview/build_duration") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/build_duration",
      "@representation" => "standard",
      "build_duration"  => builds_result
    }}
  end

  describe "build_duration on public empty repository" do
    before  {
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end
      get("/v3/repo/#{repo.id}/overview/build_duration") }
    example { expect(last_response).to be_ok             }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/build_duration",
      "@representation" => "standard",
      "build_duration"  => []
    }}
  end

  describe "private repository, not authenticated" do
    before  { repo.update_attribute(:private, true)              }
    before  { get("/v3/repo/#{repo.id}/overview/build_duration") }
    before  { repo.update_attribute(:private, false)             }
    example { expect(last_response).to be_not_found              }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "private repository, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)  }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"}                         }
    before        { Travis::API::V3::Models::Build.where(repository_id: repo).each do |build| build.destroy end
                    Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                              }
    before        { get("/v3/repo/#{repo.id}/overview/build_duration", {}, headers)    }
    after         { repo.update_attribute(:private, false)                             }
    example       { expect(last_response).to be_ok                                     }
    example       { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/build_duration",
      "@representation" => "standard",
      "build_duration"  => []
    }}
  end
end
