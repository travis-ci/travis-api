require 'spec_helper'

describe Travis::API::V3::Services::Overview::GetRecentBuildHistory do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:builds) { repo.default_branch.builds.last(10) }

  describe "fetching recent build history on a public repository" do
    before     { get("/v3/repo/#{repo.id}/overview/recent_build_history")   }
    example    { expect(last_response).to be_ok }
  end

  describe "fetching history from non-existing repo" do
    before     { get("/v3/repo/1231987129387218/overview/recent_build_history")  }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "overview not found (or insufficient access)",
      "resource_type" => "overview"
    }}
  end

  describe "recent build hitsory on public repository dynamic" do
    before     { get("/v3/repo/#{repo.id}/overview/recent_build_history") }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
      "@type" => "overview",
      "@href" => "/v3/repo/#{repo.id}/overview/recent_build_history",
      "@representation" => "standard",
      "recent_build_history" => {
        Date.today => {
          'passed' => 0,
          'error' => 0,
          'failed' => 0
        },
        Date.today - 1 => {
          'passed' => 0,
          'error' => 0,
          'failed' => 0
        },
        Date.today - 2 => {
          'passed' => 0,
          'error' => 0,
          'failed' => 0
        },
        Date.today - 3 => {
          'passed' => 0,
          'error' => 0,
          'failed' => 0
        },
        Date.today - 4 => {
          'passed' => 0,
          'error' => 0,
          'failed' => 0
        },
        Date.today - 5 => {
          'passed' => 0,
          'error' => 0,
          'failed' => 0
        },
        Date.today - 6 => {
          'passed' => 0,
          'error' => 0,
          'failed' => 0
        },
        Date.today - 7 => {
          'passed' => 0,
          'error' => 0,
          'failed' => 0
        },
        Date.today - 8 => {
          'passed' => 0,
          'error' => 0,
          'failed' => 0
        },
        Date.today - 9 => {
          'passed' => 0,
          'error' => 0,
          'failed' => 0
        }
      }
  }}
  end

end
