require 'spec_helper'

describe Travis::API::V3::Services::Repository::Find do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  before { repo.default_branch.save! }

  describe "public repository, existing branch" do
    before     { get("/v3/repo/#{repo.id}/branch/master") }
    example    { expect(last_response).to be_ok           }
    example    { expect(JSON.load(body)).to be ==         {
      "@type"            => "branch",
      "@href"            => "/v3/repo/#{repo.id}/branch/master",
      "name"             => "master",
      "repository"       => {
        "@type"          => "repository",
        "@href"          => "/v3/repo/#{repo.id}",
        "id"             => repo.id,
        "slug"           => "svenfuchs/minimal"},
      "last_build"       => {
        "@type"          => "build",
        "@href"          => "/v3/build/#{repo.default_branch.last_build.id}",
        "id"             => repo.default_branch.last_build.id,
        "number"         => "3",
        "state"          => "configured",
        "duration"       => nil,
        "event_type"     => "push",
        "previous_state" => "passed",
        "started_at"     => "2010-11-12T13:00:00Z",
        "finished_at"    => nil}}}
  end
end