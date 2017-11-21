describe Travis::API::V3::Services::Build::Find, set_app: true do
  include Support::Formats
  let(:repo)   { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build)  { repo.builds.first }
  let(:stages) { build.stages }
  let(:jobs)   { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:parsed_body) { JSON.load(body) }

  before do
    build.update_attributes(sender_id: repo.owner.id, sender_type: 'User')
    test   = build.stages.create(number: 1, name: 'test')
    deploy = build.stages.create(number: 2, name: 'deploy')
    build.jobs[0, 2].each { |job| job.update_attributes!(stage: test) }
    build.jobs[2, 2].each { |job| job.update_attributes!(stage: deploy) }
    build.reload
  end

  describe "fetching build on a public repository " do
    before     { get("/v3/build/#{build.id}")   }
    example    { expect(last_response).to be_ok }
  end

  describe "fetching a non-existing build" do
    before     { get("/v3/build/1231987129387218")  }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "build not found (or insufficient access)",
      "resource_type" => "build"
    })}
  end

  describe "build on public repository, no pull access" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: false) }
    before     { get("/v3/build/#{build.id}") }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to eql_json({
      "@type"               => "build",
      "@href"               => "/v3/build/#{build.id}",
      "@representation"     => "standard",
      "@permissions"        => {
        "read"              => true,
        "cancel"            => false,
        "restart"           => false},
      "id"                  => build.id,
      "number"              => build.number,
      "state"               => build.state,
      "duration"            => nil,
      "event_type"          => "push",
      "previous_state"      => build.previous_state,
      "pull_request_number" => build.pull_request_number,
      "pull_request_title"  => build.pull_request_title,
      "started_at"          => "2010-11-12T13:00:00Z",
      "finished_at"         => nil,
      "updated_at"          => json_format_time_with_ms(build.updated_at),
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
         "state"            => stages[0].state,
         "started_at"       => stages[1].started_at,
         "finished_at"      => stages[1].finished_at}],
      "repository"          => {
        "@type"             => "repository",
        "@href"             => "/v3/repo/#{repo.id}",
        "@representation"   => "minimal",
        "id"                => repo.id,
        "name"              => repo.name,
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
      "created_by"          => {
        "@type"             => "user",
        "@href"             => "/v3/user/1",
        "@representation"   => "minimal",
        "id"                => 1,
        "login"             => "svenfuchs"}
    })}
  end

  describe "build private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true) }
    before        { get("/v3/build/#{build.id}", {}, headers) }
    after         { repo.update_attribute(:private, false) }
    example       { expect(last_response).to be_ok  }
    example    { expect(parsed_body).to eql_json({
      "@type"               => "build",
      "@href"               => "/v3/build/#{build.id}",
      "@representation"     => "standard",
      "@permissions"        => {
        "read"              => true,
        "cancel"            => true,
        "restart"           => true},
      "id"                  => build.id,
      "number"              => build.number,
      "state"               => build.state,
      "duration"            => nil,
      "event_type"          => "push",
      "previous_state"      => build.previous_state,
      "pull_request_number" => build.pull_request_number,
      "pull_request_title"  => build.pull_request_title,
      "started_at"          => "2010-11-12T13:00:00Z",
      "finished_at"         => nil,
      "updated_at"          => json_format_time_with_ms(build.updated_at),
      "jobs"                => [{
        "@type"             => "job",
        "@href"             => "/v3/job/#{jobs[0].id}",
        "@representation"   => "minimal",
        "id"                => jobs[0].id},
       {"@type"             => "job",
        "@href"             => "/v3/job/#{jobs[1].id}",
        "@representation"   => "minimal",
        "id"                => jobs[1].id},
       {"@type"             => "job",
        "@href"             => "/v3/job/#{jobs[2].id}",
        "@representation"   => "minimal",
        "id"                => jobs[2].id},
       {"@type"             => "job",
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
         "state"            => stages[0].state,
         "started_at"       => stages[1].started_at,
         "finished_at"      => stages[1].finished_at}],
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
      "created_by"          => {
        "@type"             => "user",
        "@href"             => "/v3/user/1",
        "@representation"   => "minimal",
        "id"                => 1,
        "login"             => "svenfuchs"}
    })}
  end

  describe "build on public repository, no pull access" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: false) }
    before     { get("/v3/build/#{build.id}") }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to eql_json({
      "@type"               => "build",
      "@href"               => "/v3/build/#{build.id}",
      "@representation"     => "standard",
      "@permissions"        => {
        "read"              => true,
        "cancel"            => false,
        "restart"           => false},
      "id"                  => build.id,
      "number"              => build.number,
      "state"               => build.state,
      "duration"            => nil,
      "event_type"          => "push",
      "previous_state"      => build.previous_state,
      "pull_request_number" => build.pull_request_number,
      "pull_request_title"  => build.pull_request_title,
      "started_at"          => "2010-11-12T13:00:00Z",
      "finished_at"         => nil,
      "updated_at"          => json_format_time_with_ms(build.updated_at),
      "repository"          => {
        "@type"             => "repository",
        "@href"             => "/v3/repo/#{repo.id}",
        "@representation"   => "minimal",
        "id"                => repo.id,
        "name"              => repo.name,
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
         "state"            => stages[0].state,
         "started_at"       => stages[1].started_at,
         "finished_at"      => stages[1].finished_at}],
      "created_by"          => {
        "@type"             => "user",
        "@href"             => "/v3/user/1",
        "@representation"   => "minimal",
        "id"                => 1,
        "login"             => "svenfuchs"}
    })}
  end

  describe "build for a tag push event" do
    before  { build.create_tag(repository: repo, name: 'v1.0.0') }
    before  { build.save! } # not sure why i have to save it, any way around this?
    before  { get("/v3/build/#{build.id}") }

    example { expect(last_response).to be_ok  }
    example { expect(parsed_body['tag']).to eql_json({
      "@type"           => "tag",
      "@representation" => "minimal",
      "repository_id"   => 1,
      "name"            => "v1.0.0",
      "last_build_id"   => nil
    })}
  end
end
