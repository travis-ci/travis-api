describe Travis::API::V3::Services::Builds::Find, set_app: true do
  include Support::Formats
  let(:repo)   { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build)  { repo.builds.first }
  let(:stages) { build.stages }
  let(:jobs)   { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:parsed_body) { JSON.load(body) }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_debug', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  before do
    # TODO should this go into the scenario? is it ok to keep it here?
    build.update!(sender_id: repo.owner.id, sender_type: 'User')
    build.update!(branch_name: 'master', branch_id: 1)
    test   = build.stages.create(number: 1, name: 'test')
    deploy = build.stages.create(number: 2, name: 'deploy')
    build.jobs[0, 2].each { |job| job.update!(stage: test) }
    build.jobs[2, 2].each { |job| job.update!(stage: deploy) }
    build.reload
    build.jobs.each(&:reload)
  end

  describe "fetching builds on a public repository by slug" do
    before     { get("/v3/repo/svenfuchs%2Fminimal/builds")     }
    example    { expect(last_response).to be_ok }
  end

  describe "fetching builds on a non-existing repository by slug" do
    before     { get("/v3/repo/svenfuchs%2Fminimal1/builds")     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    })}
  end

  xdescribe "builds on public repository" do
    before     { get("/v3/repo/#{repo.id}/builds?limit=1") }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to eql_json({
      "@type"                 => "builds",
      "@href"                 => "/v3/repo/#{repo.id}/builds?limit=1",
      "@representation"       => "standard",
      "@pagination"           => {
        "limit"               => 1,
        "offset"              => 0,
        "count"               => 3,
        "is_first"            => true,
        "is_last"             => false,
        "next"                => {
          "@href"             => "/v3/repo/#{repo.id}/builds?limit=1&offset=1",
          "offset"            => 1,
          "limit"             => 1},
        "prev"                => nil,
        "first"               => {
          "@href"             => "/v3/repo/#{repo.id}/builds?limit=1",
          "offset"            => 0,
          "limit"             => 1 },
        "last"                => {
          "@href"             => "/v3/repo/#{repo.id}/builds?limit=1&offset=2",
          "offset"            => 2,
          "limit"             => 1 }},
      "builds"                => [{
        "@type"               => "build",
        "@href"               => "/v3/build/#{build.id}",
        "@representation"     => "standard",
        "@permissions"        => {
          "read"              => true,
          "cancel"            => false,
          "restart"           => false,
          "prioritize"        => false },
        "id"                  => build.id,
        "number"              => "3",
        "state"               => "configured",
        "duration"            => nil,
        "event_type"          => "push",
        "previous_state"      => "passed",
        "pull_request_number" => build.pull_request_number,
        "pull_request_title"  => build.pull_request_title,
        "private"             => false,
        "priority"            => false,
        "started_at"          => "2010-11-12T13:00:00Z",
        "finished_at"         => nil,
        "updated_at"          => json_format_time_with_ms(build.updated_at),
        "repository"          => {
          "@type"             => "repository",
          "@href"             => "/v3/repo/#{repo.id}",
          "@representation"   => "minimal",
          "id"                => repo.id,
          "name"              => "minimal",
          "slug"              => "svenfuchs/minimal"},
        "branch"              => {
          "@type"             => "branch",
          "@href"             => "/v3/repo/#{repo.id}/branch/master",
          "@representation"   => "minimal",
          "name"              => "master"},
        "tag"                 => nil,
        "commit"              => {
          "@type"             => "commit",
          "@representation"   => "minimal",
          "id"                => 5,
          "sha"               => "add057e66c3e1d59ef1f",
          "ref"               => "refs/heads/master",
          "message"           => "unignore Gemfile.lock",
          "compare_url"       => "https://github.com/svenfuchs/minimal/compare/master...develop",
          "committed_at"      => "2010-11-12T12:55:00Z"},
        "jobs"                => [
          {
          "@type"             => "job",
          "@href"             => "/v3/job/#{jobs[0].id}",
          "@representation"   => "minimal",
          "id"                => jobs[0].id},
          {
          "@type"             => "job",
          "@href"             => "/v3/job/#{jobs[1].id}",
          "@representation"   => "minimal",
          "id"                => jobs[1].id},
          {
          "@type"             => "job",
          "@href"             => "/v3/job/#{jobs[2].id}",
          "@representation"   => "minimal",
          "id"                => jobs[2].id},
          {
          "@type"             => "job",
          "@href"             => "/v3/job/#{jobs[3].id}",
          "@representation"   => "minimal",
          "id"                => jobs[3].id}],
        "stages"              => [{
           "@type"            => "stage",
           "@representation"  => "minimal",
           "id"               => stages[0].id,
           "number"           => 1,
           "name"             => "test",
           "state"            => stages[0].state,
           "started_at"       => stages[0].started_at,
           "finished_at"      => stages[0].finished_at},
          {"@type"            => "stage",
           "@representation" => "minimal",
           "id"               => stages[1].id,
           "number"          => 2,
           "name"             => "deploy",
           "state"            => stages[1].state,
           "started_at"       => stages[1].started_at,
           "finished_at"      => stages[1].finished_at}],
        "created_by"          => {
          "@type"             => "user",
          "@href"             => "/v3/user/1",
          "@representation"   => "minimal",
          "id"                => 1,
          "login"             => "svenfuchs"}
      }]
    })}
  end

  xdescribe "private builds on public repository" do
    before     { repo.builds.last.update_attribute(:private, true) }
    before     { get("/v3/repo/#{repo.id}/builds?limit=1") }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to eql_json({
      "@type"                 => "builds",
      "@href"                 => "/v3/repo/#{repo.id}/builds?limit=1",
      "@representation"       => "standard",
      "@pagination"           => {
        "limit"               => 1,
        "offset"              => 0,
        "count"               => 2,
        "is_first"            => true,
        "is_last"             => false,
        "next"                => {
          "@href"             => "/v3/repo/#{repo.id}/builds?limit=1&offset=1",
          "offset"            => 1,
          "limit"             => 1},
        "prev"                => nil,
        "first"               => {
          "@href"             => "/v3/repo/#{repo.id}/builds?limit=1",
          "offset"            => 0,
          "limit"             => 1 },
        "last"                => {
          "@href"             => "/v3/repo/#{repo.id}/builds?limit=1&offset=1",
          "offset"            => 1,
          "limit"             => 1 }},
      "builds"                => [{
        "@type"               => "build",
        "@href"               => "/v3/build/#{build.id}",
        "@representation"     => "standard",
        "@permissions"        => {
          "read"              => true,
          "cancel"            => false,
          "restart"           => false,
          "prioritize"        => false},
        "id"                  => build.id,
        "number"              => "3",
        "state"               => "configured",
        "duration"            => nil,
        "event_type"          => "push",
        "previous_state"      => "passed",
        "pull_request_number" => build.pull_request_number,
        "pull_request_title"  => build.pull_request_title,
        "private"             => false,
        "priority"            => false,
        "started_at"          => "2010-11-12T13:00:00Z",
        "finished_at"         => nil,
        "updated_at"          => json_format_time_with_ms(build.updated_at),
        "repository"          => {
          "@type"             => "repository",
          "@href"             => "/v3/repo/#{repo.id}",
          "@representation"   => "minimal",
          "id"                => repo.id,
          "name"              => "minimal",
          "slug"              => "svenfuchs/minimal"},
        "branch"              => {
          "@type"             => "branch",
          "@href"             => "/v3/repo/#{repo.id}/branch/master",
          "@representation"   => "minimal",
          "name"              => "master"},
        "tag"                 => nil,
        "commit"              => {
          "@type"             => "commit",
          "@representation"   => "minimal",
          "id"                => 5,
          "sha"               => "add057e66c3e1d59ef1f",
          "ref"               => "refs/heads/master",
          "message"           => "unignore Gemfile.lock",
          "compare_url"       => "https://github.com/svenfuchs/minimal/compare/master...develop",
          "committed_at"      => "2010-11-12T12:55:00Z"},
        "jobs"                => [
          {
          "@type"             => "job",
          "@href"             => "/v3/job/#{jobs[0].id}",
          "@representation"   => "minimal",
          "id"                => jobs[0].id},
          {
          "@type"             => "job",
          "@href"             => "/v3/job/#{jobs[1].id}",
          "@representation"   => "minimal",
          "id"                => jobs[1].id},
          {
          "@type"             => "job",
          "@href"             => "/v3/job/#{jobs[2].id}",
          "@representation"   => "minimal",
          "id"                => jobs[2].id},
          {
          "@type"             => "job",
          "@href"             => "/v3/job/#{jobs[3].id}",
          "@representation"   => "minimal",
          "id"                => jobs[3].id}],
        "stages"              => [{
           "@type"            => "stage",
           "@representation"  => "minimal",
           "id"               => stages[0].id,
           "number"           => 1,
           "name"             => "test",
           "state"            => stages[0].state,
           "started_at"       => stages[0].started_at,
           "finished_at"      => stages[0].finished_at},
          {"@type"            => "stage",
           "@representation" => "minimal",
           "id"               => stages[1].id,
           "number"          => 2,
           "name"             => "deploy",
           "state"            => stages[1].state,
           "started_at"       => stages[1].started_at,
           "finished_at"      => stages[1].finished_at}],
        "created_by"          => {
          "@type"             => "user",
          "@href"             => "/v3/user/1",
          "@representation"   => "minimal",
          "id"                => 1,
          "login"             => "svenfuchs"}
      }]
    })}
  end

  xdescribe "builds private repository, private API, authenticated as user with access" do
    let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}/builds?limit=1", {}, headers)                           }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example    { expect(parsed_body).to eql_json({
      "@type"                 => "builds",
      "@href"                 => "/v3/repo/#{repo.id}/builds?limit=1",
      "@representation"       => "standard",
      "@pagination"           => {
        "limit"               => 1,
        "offset"              => 0,
        "count"               => 3,
        "is_first"            => true,
        "is_last"             => false,
        "next"                => {
          "@href"             => "/v3/repo/#{repo.id}/builds?limit=1&offset=1",
          "offset"            => 1,
          "limit"             => 1},
        "prev"                => nil,
        "first"               => {
          "@href"             => "/v3/repo/#{repo.id}/builds?limit=1",
          "offset"            => 0,
          "limit"             => 1 },
        "last"                => {
          "@href"             => "/v3/repo/#{repo.id}/builds?limit=1&offset=2",
          "offset"            => 2,
          "limit"             => 1 }},
      "builds"                => [{
        "@type"               => "build",
        "@href"               => "/v3/build/#{build.id}",
        "@representation"     => "standard",
        "@permissions"        => {
          "read"              => true,
          "cancel"            => true,
          "restart"           => true,
          "prioritize"        => false },
        "id"                  => build.id,
        "number"              => "3",
        "state"               => "configured",
        "duration"            => nil,
        "event_type"          => "push",
        "previous_state"      => "passed",
        "pull_request_number" => build.pull_request_number,
        "pull_request_title"  => build.pull_request_title,
        "private"             => false,
        "priority"            => false,
        "started_at"          => "2010-11-12T13:00:00Z",
        "finished_at"         => nil,
        "updated_at"          => json_format_time_with_ms(build.updated_at),
        "repository"          => {
          "@type"             => "repository",
          "@href"             => "/v3/repo/#{repo.id}",
          "@representation"   => "minimal",
          "id"                => repo.id,
          "name"              => "minimal",
          "slug"              => "svenfuchs/minimal"},
        "branch"              => {
          "@type"             => "branch",
          "@href"             => "/v3/repo/#{repo.id}/branch/master",
          "@representation"   => "minimal",
          "name"              => "master"},
        "tag"                 => nil,
        "commit"              => {
          "@type"             => "commit",
          "@representation"   => "minimal",
          "id"                => 5,
          "sha"               => "add057e66c3e1d59ef1f",
          "ref"               => "refs/heads/master",
          "message"           => "unignore Gemfile.lock",
          "compare_url"       => "https://github.com/svenfuchs/minimal/compare/master...develop",
          "committed_at"      => "2010-11-12T12:55:00Z"},
        "jobs"                => [
          {
          "@type"             => "job",
          "@href"             => "/v3/job/#{jobs[0].id}",
          "@representation"   => "minimal",
          "id"                => jobs[0].id},
          {
          "@type"             => "job",
          "@href"             => "/v3/job/#{jobs[1].id}",
          "@representation"   => "minimal",
          "id"                => jobs[1].id},
          {
          "@type"             => "job",
          "@href"             => "/v3/job/#{jobs[2].id}",
          "@representation"   => "minimal",
          "id"                => jobs[2].id},
          {
          "@type"             => "job",
          "@href"             => "/v3/job/#{jobs[3].id}",
          "@representation"   => "minimal",
          "id"                => jobs[3].id}],
        "stages"              => [{
           "@type"            => "stage",
           "@representation"  => "minimal",
           "id"               => stages[0].id,
           "number"           => 1,
           "name"             => "test",
           "state"            => stages[0].state,
           "started_at"       => stages[0].started_at,
           "finished_at"      => stages[0].finished_at},
          {"@type"            => "stage",
           "@representation" => "minimal",
           "id"               => stages[1].id,
           "number"          => 2,
           "name"             => "deploy",
           "state"            => stages[1].state,
           "started_at"       => stages[1].started_at,
           "finished_at"      => stages[1].finished_at}],
        "created_by"          => {
          "@type"             => "user",
          "@href"             => "/v3/user/1",
          "@representation"   => "minimal",
          "id"                => 1,
          "login"             => "svenfuchs"}
      }]
    })}
  end

  xdescribe "including branch.name params on existing branch" do
    before  { get("/v3/repo/#{repo.id}/builds?branch.name=master&limit=1") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body['builds'].first['branch']['name']).to be == ("master") }
  end

  describe "including branch.name params on non-existing branch" do
    before  { get("/v3/repo/#{repo.id}/builds?branch.name=missing&limit=1") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body['builds']).to be == [] }
  end

  describe "including created_by params with non-existing login" do
    before  { get("/v3/repo/#{repo.id}/builds?build.created_by=xxxxxx") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body['builds']).to be == []}
  end

  describe "including created_by params with existing login but no created builds" do
    before  { get("/v3/repo/#{repo.id}/builds?build.created_by=josevalim") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body['builds']).to be == [] }
  end

  describe "including created_by params with existing login" do
    before  { get("/v3/repo/#{repo.id}/builds?build.created_by=josevalim,svenfuchs,travis-ci") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body['builds'].size).to be == (1) }
    example { expect(parsed_body['builds'].first['created_by']['id']).to be == (repo.owner.id) }
  end

  describe "build for a tag push event" do
    before  { build.create_tag(repository: repo, name: 'v1.0.0') }
    before  { build.save! } # not sure why i have to save it, any way around this?
    before  { get("/v3/repo/svenfuchs%2Fminimal/builds")     }

    example { expect(last_response).to be_ok  }
    example { expect(parsed_body['builds'][0]['tag']).to eql_json({
      "@type"           => "tag",
      "@representation" => "minimal",
      "repository_id"   => 1,
      "name"            => "v1.0.0",
      "last_build_id"   => nil
    })}
  end
end
