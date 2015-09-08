require 'spec_helper'

describe Travis::API::V3::Services::Branches::Find do
  let(:repo)   { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:branch) { Travis::API::V3::Models::Branch.where(repository_id: repo.id).first }
  let(:build)  { branch.last_build }
  let(:jobs)   { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:parsed_body) { JSON.load(body) }

  describe "fetching branches on a public repository by slug" do
    before     { get("/v3/repo/svenfuchs%2Fminimal/branches")     }
    example    { expect(last_response).to be_ok }
  end

  describe "fetching branches on a non-existing repository by slug" do
    before     { get("/v3/repo/svenfuchs%2Fminimal1/branches")     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "builds on public repository" do
    before     { get("/v3/repo/#{repo.id}/branches?limit=1") }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
      "@type"              => "branches",
      "@href"              => "/v3/repo/#{repo.id}/branches?limit=1",
      "@representation"    => "standard",
      "@pagination"        => {
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 1,
        "is_first"         => true,
        "is_last"          => true,
        "next"             => nil,
        "prev"             => nil,
        "first"            => {
          "@href"          => "/v3/repo/#{repo.id}/branches?limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/#{repo.id}/branches?limit=1",
          "offset"         => 0,
          "limit"          => 1 }},
      "branches"           => [{
        "@type"            => "branch",
        "@href"            => "/v3/repo/#{repo.id}/branch/#{branch.name}",
        "@representation"  => "standard",
        "name"             => branch.name,
        "repository"       => {
          "@type"          => "repository",
          "@href"          => "/v3/repo/#{repo.id}",
          "@representation"=> "minimal",
          "id"             => repo.id,
          "slug"           => "svenfuchs/minimal" },
        "last_build"       => {
          "@type"          => "build",
          "@href"          => "/v3/build/#{build.id}",
          "@representation"=> "minimal",
          "id"             => build.id,
          "number"         => build.number,
          "state"          => build.state,
          "duration"       => nil,
          "event_type"     => "push",
          "previous_state" => "passed",
          "started_at"     => "2010-11-12T13:00:00Z",
          "finished_at"    => nil,
          "jobs"           => [{
            "@type"        => "job",
            "@href"        => "/v3/job/#{jobs[0].id}",
            "@representation"=> "minimal",
            "id"           => jobs[0].id },
            {
            "@type"        => "job",
            "@href"        => "/v3/job/#{jobs[1].id}",
            "@representation"=>"minimal",
            "id"           => jobs[1].id },
            {
            "@type"        => "job",
            "@href"        => "/v3/job/#{jobs[2].id}",
            "@representation"=>"minimal",
            "id"           => jobs[2].id },
            {
            "@type"        => "job",
            "@href"        => "/v3/job/#{jobs[3].id}",
            "@representation"=>"minimal",
            "id"           => jobs[3].id }]},
        "exists_on_github" => true }]}
    }
  end

  describe "branches private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}/branches?limit=1", {}, headers)                           }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example    { expect(parsed_body).to be == {
      "@type"              => "branches",
      "@href"              => "/v3/repo/#{repo.id}/branches?limit=1",
      "@representation"    => "standard",
      "@pagination"        => {
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 1,
        "is_first"         => true,
        "is_last"          => true,
        "next"             => nil,
        "prev"             => nil,
        "first"            => {
          "@href"          => "/v3/repo/#{repo.id}/branches?limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/#{repo.id}/branches?limit=1",
          "offset"         => 0,
          "limit"          => 1 }},
      "branches"           => [{
        "@type"            => "branch",
        "@href"            => "/v3/repo/#{repo.id}/branch/#{branch.name}",
        "@representation"  => "standard",
        "name"             => branch.name,
        "repository"       => {
          "@type"          => "repository",
          "@href"          => "/v3/repo/#{repo.id}",
          "@representation"=> "minimal",
          "id"             => repo.id,
          "slug"           => "svenfuchs/minimal" },
        "last_build"       => {
          "@type"          => "build",
          "@href"          => "/v3/build/#{build.id}",
          "@representation"=> "minimal",
          "id"             => build.id,
          "number"         => build.number,
          "state"          => build.state,
          "duration"       => nil,
          "event_type"     => "push",
          "previous_state" => "passed",
          "started_at"     => "2010-11-12T13:00:00Z",
          "finished_at"    => nil,
          "jobs"           => [{
            "@type"        => "job",
            "@href"        => "/v3/job/#{jobs[0].id}",
            "@representation"=> "minimal",
            "id"           => jobs[0].id },
            {
            "@type"        => "job",
            "@href"        => "/v3/job/#{jobs[1].id}",
            "@representation"=>"minimal",
            "id"           => jobs[1].id },
            {
            "@type"        => "job",
            "@href"        => "/v3/job/#{jobs[2].id}",
            "@representation"=>"minimal",
            "id"           => jobs[2].id },
            {
            "@type"        => "job",
            "@href"        => "/v3/job/#{jobs[3].id}",
            "@representation"=>"minimal",
            "id"           => jobs[3].id }]},
        "exists_on_github" => true }]}
    }
  end
end
