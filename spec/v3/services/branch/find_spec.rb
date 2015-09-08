require 'spec_helper'

describe Travis::API::V3::Services::Repository::Find do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:jobs)  { Travis::API::V3::Models::Build.find(build.id).jobs }
  before { repo.default_branch.save! }

  describe "public repository, existing branch" do
    before     { get("/v3/repo/#{repo.id}/branch/master") }
    example    { expect(last_response).to be_ok           }
    example    { expect(JSON.load(body)).to be == {
      "@type"            => "branch",
      "@href"            => "/v3/repo/#{repo.id}/branch/master",
      "@representation"  => "standard",
      "name"             => "master",
      "repository"       => {
        "@type"          => "repository",
        "@href"          => "/v3/repo/#{repo.id}",
        "@representation"=> "minimal",
        "id"             => repo.id,
        "slug"           => "svenfuchs/minimal"},
      "last_build"       => {
        "@type"          => "build",
        "@href"          => "/v3/build/#{repo.default_branch.last_build.id}",
        "@representation"=> "minimal",
        "id"             => repo.default_branch.last_build.id,
        "number"         => "3",
        "state"          => "configured",
        "duration"       => nil,
        "event_type"     => "push",
        "previous_state" => "passed",
        "started_at"     => "2010-11-12T13:00:00Z",
        "finished_at"    => nil,
        "jobs"           => [{
          "@type"        => "job",
          "@href"        => "/v3/job/#{jobs[0].id}",
          "@representation"=> "minimal",
          "id"             => jobs[0].id},
         {"@type"       => "job",
          "@href"       => "/v3/job/#{jobs[1].id}",
          "@representation"=>"minimal",
          "id"          => jobs[1].id},
         {"@type"       => "job",
          "@href"       => "/v3/job/#{jobs[2].id}",
          "@representation"=>"minimal",
          "id"          => jobs[2].id},
         {"@type"       => "job",
          "@href"       => "/v3/job/#{jobs[3].id}",
          "@representation"=>"minimal",
          "id"          =>jobs[3].id}]},
      "exists_on_github"=> true
    }}
  end
end
