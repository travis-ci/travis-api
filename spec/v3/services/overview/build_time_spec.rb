require 'spec_helper'

describe Travis::API::V3::Services::Overview::BuildTime do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  describe "fetching build_time data on a public repository" do
    before  { get("/v3/repo/#{repo.id}/overview/build_time") }
    example { expect(last_response).to be_ok             }
  end

  describe "fetching build_time from non-existing repo" do
    before  { get("/v3/repo/1231987129387218/overview/build_time") }
    example { expect(last_response).to be_not_found            }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "build_time on public repository" do
    before  {
      finished = DateTime.now
      started = finished - 1
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end
      Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 5, started_at: started, finished_at: finished, branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 4, started_at: started, finished_at: finished, branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 2, started_at: started, finished_at: finished, branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now    , started_at: started, finished_at: finished, branch_name: repo.default_branch.name)
      get("/v3/repo/#{repo.id}/overview/build_time") }
    example { expect(last_response).to be_ok     }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/build_time",
      "@representation" => "standard",
      "build_time"      => {
          "last_thirty_days"   => "345600",
          "thrity_days_before" => "0"
      }
    }}
  end
end
