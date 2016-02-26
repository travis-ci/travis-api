require 'spec_helper'

describe Travis::API::V3::Services::Overview::GetRecentBuildHistory do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:builds) { repo.default_branch.builds.last(10) }
  let(:branch) { repo.default_branch }

  describe "fetching recent build history on a public repository" do
    before  { get("/v3/repo/#{repo.id}/overview/build_history") }
    example { expect(last_response).to be_ok                    }
  end

  describe "fetching history from non-existing repo" do
    before  { get("/v3/repo/1231987129387218/overview/build_history") }
    example { expect(last_response).to be_not_found                   }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "recent build history on public repository dynamic" do
    before  {
      Travis::API::V3::Models::Build.create(repository_id: repo.id, started_at: DateTime.now, state: 'passed',  branch_name: branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, started_at: DateTime.now, state: 'failed',  branch_name: branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, started_at: DateTime.now, state: 'errored', branch_name: branch.name)
      get("/v3/repo/#{repo.id}/overview/build_history") }
    example { expect(last_response).to be_ok            }
    example { expect(parsed_body).to be == {
      "@type"                => "overview",
      "@href"                => "/v3/repo/#{repo.id}/overview/build_history",
      "@representation"      => "standard",
      "recent_build_history" => {
        Date.today.iso8601 => {
          'passed'  => 1,
          'errored' => 1,
          'failed'  => 1
        }
      }
    }}
  end

  describe "recent build history on public repository dynamic, fringe cases" do
    before  {
      Travis::API::V3::Models::Build.create(repository_id: repo.id, started_at: DateTime.now - 9,  state: 'passed',  branch_name: branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, started_at: DateTime.now,      state: 'failed',  branch_name: branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, started_at: DateTime.now - 10, state: 'errored', branch_name: branch.name)
      get("/v3/repo/#{repo.id}/overview/build_history") }
    example { expect(last_response).to be_ok            }
    example { expect(parsed_body).to be == {
      "@type"                => "overview",
      "@href"                => "/v3/repo/#{repo.id}/overview/build_history",
      "@representation"      => "standard",
      "recent_build_history" => {
        Date.today.iso8601 => {
          'failed' => 1
        },
        (Date.today - 9).iso8601 => {
          'passed' => 1
        }
      }
    }}
  end

  describe "recent build hitsory on public empty repository" do
    before  { get("/v3/repo/#{repo.id}/overview/build_history") }
    example { expect(last_response).to be_ok                    }
    example { expect(parsed_body).to be == {
      "@type"                => "overview",
      "@href"                => "/v3/repo/#{repo.id}/overview/build_history",
      "@representation"      => "standard",
      "recent_build_history" => {}
    }}
  end

  describe "private repository, not authenticated" do
    before  { repo.update_attribute(:private, true)             }
    before  { get("/v3/repo/#{repo.id}/overview/build_history") }
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
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}/overview/build_history", {}, headers)    }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(parsed_body).to be == {
      "@type"                => "overview",
      "@href"                => "/v3/repo/#{repo.id}/overview/build_history",
      "@representation"      => "standard",
      "recent_build_history" => {}
    }}
  end
end
