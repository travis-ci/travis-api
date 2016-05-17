require 'spec_helper'

describe Travis::API::V3::Services::Overview::History do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  describe "fetching history data on a public repository" do
    before  { get("/v3/repo/#{repo.id}/overview/history") }
    example { expect(last_response).to be_ok             }
  end

  describe "fetching history from non-existing repo" do
    before  { get("/v3/repo/1231987129387218/overview/history") }
    example { expect(last_response).to be_not_found            }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "history on public repository" do
    before  {
      finished = DateTime.now
      started = finished - 1
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end
      Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 5, started_at: started, finished_at: finished, branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 4, started_at: started, finished_at: finished, branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 2, started_at: started, finished_at: finished, branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now    , started_at: started, finished_at: finished, branch_name: repo.default_branch.name)
      get("/v3/repo/#{repo.id}/overview/history") }
    example { expect(last_response).to be_ok     }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/history",
      "@representation" => "standard",
      "history"         => {
          "builds"  => 4,
          "minutes" => 345600
      }
    }}
  end
end
