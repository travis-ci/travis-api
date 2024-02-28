describe Travis::API::V3::Services::Builds::ForCurrentUser, set_app: true do
  include Support::Formats
  let(:repo)   { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build)  { repo.builds.first }
  let(:branch)    { Travis::API::V3::Models::Branch.find_by(repository_id: repo.id, name: 'master') }
  let(:stages) { build.stages }
  let(:jobs)   { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:parsed_body) { JSON.load(body) }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_debug', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  before do
    # TODO should this go into the scenario? is it ok to keep it here?
    build.update!(sender_id: repo.owner.id, sender_type: 'User')
    test   = build.stages.create(number: 1, name: 'test')
    deploy = build.stages.create(number: 2, name: 'deploy')
    build.jobs[0, 2].each { |job| job.update!(stage: test) }
    build.jobs[2, 2].each { |job| job.update!(stage: deploy) }
  end


  describe "builds for current_user, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { get("/v3/builds", {}, headers)                           }
    example       { expect(last_response).to be_ok                                    }
    example    { expect(parsed_body).to eql_json({
      "@type"                 => "builds",
      "@href"                 => "/v3/builds",
      "@representation"       => "standard",
      "@pagination"           => {
        "limit"               => 100,
        "offset"              => 0,
        "count"               => 1,
        "is_first"            => true,
        "is_last"             => true,
        "next"                => nil,
        "prev"                => nil,
        "first"               => {
          "@href"             => "/v3/builds",
          "offset"            => 0,
          "limit"             => 100 },
        "last"                => {
          "@href"             => "/v3/builds",
          "offset"            => 0,
          "limit"             => 100 }},
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
        "pull_request_number" => nil,
        "pull_request_title"  => nil,
        "started_at"          => "2010-11-12T13:00:00Z",
        "finished_at"         => nil,
        "tag"                 => nil,
        "private"             => false,
        "priority"            => false,
        "updated_at"          => json_format_time_with_ms(build.reload.updated_at),
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
      }]
    })}
  end
end
