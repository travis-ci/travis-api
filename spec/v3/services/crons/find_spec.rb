require 'spec_helper'

describe Travis::API::V3::Services::Crons::Find do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:cron)  { Travis::API::V3::Models::Cron.create(repository: repo) }
  let(:parsed_body) { JSON.load(body) }

  describe "fetching all crons by repo id" do
    before     { get("/v3/repo/#{repo.id}/crons")     }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
      "@type"              => "crons",
        "@href"             => "/v3/repo/#{repo.id}/crons",
        "@representation"   => "standard",
        "@pagination"       => {
          "limit"           => 25,
          "offset"          => 0,
          "count"           => 0,
          "is_first"        => true,
          "is_last"         => true,
          "next"            => nil,
          "prev"            => nil,
          "first"           => {
                "@href"     => "/v3/repo/#{repo.id}/crons",
                "offset"    => 0,
                "limit"     => 25},
                "last"      => {
                "@href"     => "/v3/repo/#{repo.id}/crons?limit=25&offset=-25",
                "offset"    => -25,
                "limit"     => 25 }},
          "crons"           => []
    }}
  end

  describe "fetching crons on a non-existing repository by slug" do
    before     { get("/v3/repo/svenfuchs%2Fminimal1/crons")     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

end
