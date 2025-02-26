describe Travis::API::V3::Services::Build::Find, set_app: true do
  include Support::Formats
  let(:repo)   { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build)  { repo.builds.first }
  let(:stages) { build.stages }
  let(:jobs)   { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:parsed_body) { JSON.load(body) }
  let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org') }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }


  before do
    stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization))
    stub_request(:post,  'http://billingfake.travis-ci.com/usage/stats')
      .with(body: "{\"owners\":[{\"id\":1,\"type\":\"User\"}],\"query\":\"trial_allowed\"}")
      .to_return(status: 200, body: "{\"trial_allowed\": false }", headers: {})
    build.update(sender_id: repo.owner.id, sender_type: 'User')
    test   = build.stages.create(number: 1, name: 'test')
    deploy = build.stages.create(number: 2, name: 'deploy')
    build.jobs[0, 2].each { |job| job.update!(stage: test) }
    build.jobs[2, 2].each { |job| job.update!(stage: deploy) }
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
    let(:authorization) { { 'permissions' => ['repository_log_view', 'repository_settings_read'] } }
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
        "restart"           => false,
        "prioritize"        => false},
      "id"                  => build.id,
      "number"              => build.number,
      "state"               => build.state,
      "duration"            => nil,
      "event_type"          => "push",
      "previous_state"      => build.previous_state,
      "pull_request_number" => build.pull_request_number,
      "pull_request_title"  => build.pull_request_title,
      "private"             => false,
      "priority"            => false,
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
        "restart"           => true,
        "prioritize"        => false},
      "id"                  => build.id,
      "number"              => build.number,
      "state"               => build.state,
      "duration"            => nil,
      "event_type"          => "push",
      "previous_state"      => build.previous_state,
      "pull_request_number" => build.pull_request_number,
      "pull_request_title"  => build.pull_request_title,
      "private"             => false,
      "priority"            => false,
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
    let(:authorization) { { 'permissions' => ['repository_log_view', 'repository_settings_read'] } }
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
        "restart"           => false,
        "prioritize"        => false},
      "id"                  => build.id,
      "number"              => build.number,
      "state"               => build.state,
      "duration"            => nil,
      "event_type"          => "push",
      "previous_state"      => build.previous_state,
      "private"             => false,
      "priority"            => false,
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

  describe 'including a request' do
    before { build.request.messages.create(level: 'warn') }
    before { get("/v3/build/#{build.id}?include=build.request") }

    example { expect(last_response).to be_ok }
    example do
      expect(parsed_body['request']).to include(
        '@type',
        '@href',
        '@representation',
        'id',
        'state',
        'result',
        'message',
      )
    end
    it { expect(parsed_body['request']['messages'][0]['level']).to eq 'warn' }
  end

  describe 'including created_by' do
    before { get("/v3/build/#{build.id}?include=build.created_by") }

    example { expect(last_response).to be_ok }
    example do
      expect(parsed_body['created_by']).to include(
        '@type',
        '@href',
        '@representation',
        'id',
        'name',
        'avatar_url'
      )
    end
  end

  describe "private build on public repository, no pull access" do
    before     { build.update_attribute(:private, true) }
    before     { get("/v3/build/#{build.id}") }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "build not found (or insufficient access)",
      "resource_type" => "build"
    })}
  end

  describe 'including log_complete on hosted' do
    before do
      jobs.each do |j|
        stub_request(:get, "#{Travis.config.logs_api.url}/logs/#{j.id}?by=job_id&source=api").
           with(  headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization'=>'token notset',
            'Connection'=>'keep-alive',
            'Keep-Alive'=>'30',
            'User-Agent'=>'Faraday v2.7.10'
             }).
           to_return(status: 200, body: "{}", headers: {})
      end
    end

    before { get("/v3/build/#{build.id}?include=build.log_complete") }

    example { expect(last_response).to be_ok }
    example do
      expect(parsed_body).to include('log_complete')
    end
  end

  describe 'including log_complete on enterprise' do
    before do
      jobs.each do |j|
        stub_request(:get, "#{Travis.config.logs_api.url}/logs/#{j.id}?by=job_id&source=api").
           with(  headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization'=>'token notset',
            'Connection'=>'keep-alive',
            'Keep-Alive'=>'30',
            'User-Agent'=>'Faraday v2.7.10'
             }).
           to_return(status: 200, body: "{}", headers: {})
      end
    end

    before { Travis.config.enterprise = true }
    after { Travis.config.enterprise = false }

    before { get("/v3/build/#{build.id}?include=build.log_complete") }

    example { expect(last_response).to be_ok }
    example do
      expect(parsed_body).to include('log_complete')
    end
  end
end
