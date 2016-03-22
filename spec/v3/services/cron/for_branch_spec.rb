require 'spec_helper'

describe Travis::API::V3::Services::Cron::ForBranch do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:branch) { Travis::API::V3::Models::Branch.where(repository_id: repo).first }
  let(:cron)  { Travis::API::V3::Models::Cron.create(branch: branch, interval:'daily') }
  let(:parsed_body) { JSON.load(body) }

  before do
    Travis::Features.activate_owner(:cron, repo.owner)
  end

  describe "find cron job for branch with feature disabled" do
    before     { Travis::Features.deactivate_owner(:cron, repo.owner)   }
    before     { get("/v3/repo/#{repo.id}/branch/#{branch.name}/cron")   }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "cron not found (or insufficient access)",
      "resource_type" => "cron"
    }}
  end

  describe "fetching all crons by repo id" do
    before     { cron }
    before     { get("/v3/repo/#{repo.id}/branch/#{branch.name}/cron")     }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
      "@type"               => "cron",
      "@href"               => "/v3/cron/#{cron.id}",
      "@representation"     => "standard",
      "@permissions"        => {
          "read"            => true,
          "delete"          => false,
          "start"           => true },
      "id"                  => cron.id,
      "repository"          => {
          "@type"           => "repository",
          "@href"           => "/v3/repo/#{repo.id}",
          "@representation" => "minimal",
          "id"              => repo.id,
          "name"            => "minimal",
          "slug"            => "svenfuchs/minimal" },
      "branch"              => {
          "@type"           => "branch",
          "@href"           => "/v3/repo/#{repo.id}/branch/#{branch.name}",
          "@representation" => "minimal",
          "name"            => branch.name },
      "interval"            => "daily",
      "disable_by_build"     => true,
      "next_enqueuing"     => cron.next_enqueuing.strftime('%Y-%m-%dT%H:%M:%SZ')
    }}
  end

  describe "fetching crons on a non-existing repository by slug" do
    before  { get("/v3/repo/svenfuchs%2Fminimal1/branch/master/cron") }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "fetching crons on a non-existing branch" do
    before  { get("/v3/repo/#{repo.id}/branch/hopefullyNonExistingBranch/cron") }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "branch not found (or insufficient access)",
      "resource_type" => "branch"
    }}
  end

  describe "fetching crons from private repo, not authenticated" do
    before  { repo.update_attribute(:private, true)  }
    before  { get("/v3/repo/#{repo.id}/branch/#{branch.name}/cron") }
    after   { repo.update_attribute(:private, false) }
    example { expect(last_response).to be_not_found  }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

end
