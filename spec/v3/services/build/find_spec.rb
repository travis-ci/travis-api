require 'spec_helper'

describe Travis::API::V3::Services::Build::Find do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:jobs)  { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:parsed_body) { JSON.load(body) }

  describe "fetching build on a public repository " do
    before     { get("/v3/build/#{build.id}")   }
    example    { expect(last_response).to be_ok }
  end

  describe "fetching a non-existing build" do
    before     { get("/v3/build/1231987129387218")  }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "build not found (or insufficient access)",
      "resource_type" => "build"
    }}
  end

  describe "build on public repository" do
    before     { get("/v3/build/#{build.id}") }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
      "@type"              => "build",
      "@href"              => "/v3/build/#{build.id}",
      "@representation"    => "standard",
      "id"               => build.id,
      "number"           => build.number,
      "state"            => build.state,
      "duration"         => nil,
      "event_type"       => "push",
      "previous_state"   => build.previous_state,
      "started_at"       => "2010-11-12T13:00:00Z",
      "finished_at"      => nil,
      "jobs"             =>[
        {
        "@type"          => "job",
        "@href"          => "/v3/job/#{jobs[0].id}",
        "@representation"=> "minimal",
        "id"             => jobs[0].id},
        {
        "@type"          => "job",
        "@href"          => "/v3/job/#{jobs[1].id}",
        "@representation"=> "minimal",
        "id"             => jobs[1].id},
        {
        "@type"          => "job",
        "@href"          => "/v3/job/#{jobs[2].id}",
        "@representation"=> "minimal",
        "id"             => jobs[2].id},
        {
        "@type"          => "job",
        "@href"          => "/v3/job/#{jobs[3].id}",
        "@representation"=> "minimal",
        "id"             => jobs[3].id}],
      "repository"       => {
        "@type"          => "repository",
        "@href"          => "/v3/repo/#{repo.id}",
        "@representation"=> "minimal",
        "id"             => repo.id,
        "slug"           => "svenfuchs/minimal",
        "default_branch" => {
            "@type"        => "branch",
            "@href"        =>"/v3/repo/#{repo.id}/branch/master",
            "@representation"=>"minimal",
            "name"         =>"master",
            "last_build"   => {
              "@href"      => "/v3/build/#{build.id}"}}},
      "branch"           => {
        "@type"          => "branch",
        "@href"          => "/v3/repo/#{repo.id}/branch/master",
        "@representation"=> "minimal",
        "name"           => "master",
        "last_build"     => {
          "@href"        => "/v3/build/#{build.id}" }},
      "commit"           => {
        "@type"          => "commit",
        "@representation"=> "minimal",
        "id"             => 5,
        "sha"            => "add057e66c3e1d59ef1f",
        "ref"            => "refs/heads/master",
        "message"        => "unignore Gemfile.lock",
        "compare_url"    => "https://github.com/svenfuchs/minimal/compare/master...develop",
        "committed_at"   => "2010-11-12T12:55:00Z"}
    }}
  end

  describe "build private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true) }
    before        { get("/v3/build/#{build.id}", {}, headers) }
    after         { repo.update_attribute(:private, false) }
    example       { expect(last_response).to be_ok  }
    example    { expect(parsed_body).to be == {
      "@type"              => "build",
      "@href"              => "/v3/build/#{build.id}",
      "@representation"    => "standard",
      "id"               => build.id,
      "number"           => build.number,
      "state"            => build.state,
      "duration"         => nil,
      "event_type"       => "push",
      "previous_state"   => build.previous_state,
      "started_at"       => "2010-11-12T13:00:00Z",
      "finished_at"      => nil,
      "jobs"             => [{
        "@type"          => "job",
        "@href"          => "/v3/job/#{jobs[0].id}",
        "@representation"=> "minimal",
        "id"             => jobs[0].id},
       {"@type"          => "job",
        "@href"          => "/v3/job/#{jobs[1].id}",
        "@representation"=>"minimal",
        "id"             => jobs[1].id},
       {"@type"          => "job",
        "@href"          => "/v3/job/#{jobs[2].id}",
        "@representation"=>"minimal",
        "id"             => jobs[2].id},
       {"@type"          => "job",
        "@href"          => "/v3/job/#{jobs[3].id}",
        "@representation"=>"minimal",
        "id"             =>jobs[3].id}],
      "repository"       => {
        "@type"          => "repository",
        "@href"          => "/v3/repo/#{repo.id}",
        "@representation"=> "minimal",
        "id"             => repo.id,
        "slug"           => "svenfuchs/minimal",
        "default_branch" => {
            "@type"        => "branch",
            "@href"        =>"/v3/repo/#{repo.id}/branch/master",
            "@representation"=>"minimal",
            "name"         =>"master",
            "last_build"   => {
              "@href"      => "/v3/build/#{build.id}"}}},
      "branch"           => {
        "@type"          => "branch",
        "@href"          => "/v3/repo/#{repo.id}/branch/master",
        "@representation"=> "minimal",
        "name"           => "master",
        "last_build"     => {
          "@href"        => "/v3/build/#{build.id}" }},
      "commit"           => {
        "@type"          => "commit",
        "@representation"=> "minimal",
        "id"             => 5,
        "sha"            => "add057e66c3e1d59ef1f",
        "ref"            => "refs/heads/master",
        "message"        => "unignore Gemfile.lock",
        "compare_url"    => "https://github.com/svenfuchs/minimal/compare/master...develop",
        "committed_at"   => "2010-11-12T12:55:00Z"}
    }}
  end
end
