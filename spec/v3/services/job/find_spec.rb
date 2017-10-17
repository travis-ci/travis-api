describe Travis::API::V3::Services::Job::Find, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:owner_href)  { repo.owner_type.downcase }
  let(:owner_type)  { repo.owner_type.constantize }
  let(:owner)       { owner_type.find(repo.owner_id)}
  let(:build)       { repo.builds.last }
  let(:job)         { Travis::API::V3::Models::Build.find(build.id).jobs.last }
  let(:job2)        { Travis::API::V3::Models::Build.find(build.id).jobs.first }
  let(:stage)       { Travis::API::V3::Models::Stage.create!(number: 1, name: 'test') }
  let(:commit)      { job.commit }
  let(:config)      { { foo: 'bar', addons: 'anything', ssh: 'skdjf', env: 'secure'} }
  let(:parsed_body) { JSON.load(body) }

  before do
    # TODO should this go into the scenario? is it ok to keep it here?
    job.update_attributes!(stage: stage)
    job2.update_attributes!(config: config)
  end

  describe "fetching job on a public repository, no pull access" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: false) }
    before     { get("/v3/job/#{job.id}")     }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
      "@type"                 => "job",
      "@href"                 => "/v3/job/#{job.id}",
      "@representation"       => "standard",
      "@permissions"          => {
        "read"                => true,
        "cancel"              => false,
        "restart"             => false,
        "debug"               => false,
        "delete_log"          => false },
      "id"                    => job.id,
      "allow_failure"         => job.allow_failure,
      "number"                => job.number,
      "state"                 => job.state,
      "started_at"            => "2010-11-12T12:00:00Z",
      "finished_at"           => "2010-11-12T12:00:10Z",
      "build"                 => {
        "@type"               => "build",
        "@href"               => "/v3/build/#{build.id}",
        "@representation"     => "minimal",
        "id"                  => build.id,
        "number"              => build.number,
        "state"               => build.state,
        "duration"            => build.duration,
        "event_type"          => build.event_type,
        "previous_state"      => build.previous_state,
        "pull_request_number" => build.pull_request_number,
        "pull_request_title"  => build.pull_request_title,
        "started_at"          => "2010-11-12T12:00:00Z",
        "finished_at"         => "2010-11-12T12:00:10Z"},
      "stage"                 => {
        "@type"               => "stage",
        "@representation"     => "minimal",
        "id"                  => stage.id,
        "number"              => 1,
        "name"                => "test",
        "state"               => stage.state,
        "started_at"          => stage.started_at,
        "finished_at"         => stage.finished_at},
      "queue"                 => job.queue,
      "repository"            => {
        "@type"               => "repository",
        "@href"               => "/v3/repo/#{repo.id}",
        "@representation"     => "minimal",
        "id"                  => repo.id,
        "name"                => repo.name,
        "slug"                => repo.slug},
      "commit"                => {
        "@type"               => "commit",
        "@representation"     => "minimal",
        "id"                  => commit.id,
        "sha"                 => commit.commit,
        "ref"                 => commit.ref,
        "message"             => commit.message,
        "compare_url"         => commit.compare_url,
        "committed_at"        => "2010-11-12T11:50:00Z"},
      "owner"                 => {
        "@type"               => owner_type.to_s.downcase,
        "@href"               => "/v3/#{owner_href}/#{owner.id}",
        "@representation"     => "minimal",
        "id"                  => owner.id,
        "login"               => owner.login},
      "config"                => {
        "rvm"                 =>"1.9.2",
        "gemfile"             =>"test/Gemfile.rails-3.0.x",
        "language"            =>"ruby",
        "group"               =>"stable",
        "dist"                =>"precise",
        "os"                  =>"linux"}
    }}
  end

  describe "fetching a non-existing job" do
    before     { get("/v3/job/1233456789")     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         =>  "error",
      "error_type"    =>  "not_found",
      "error_message" =>  "job not found (or insufficient access)",
      "resource_type" =>  "job"
    }}
  end

  describe "fetching job on private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { Travis::API::V3::Permissions::Job.any_instance.stubs(:delete_log?).returns(true) }
    before        { get("/v3/job/#{job.id}", {}, headers)                             }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(parsed_body).to be == {
      "@type"                 => "job",
      "@href"                 => "/v3/job/#{job.id}",
      "@representation"       => "standard",
      "@permissions"          => {
        "read"                => true,
        "cancel"              => true,
        "restart"             => true,
        "debug"               => false,
        "delete_log"          => true },
      "id"                    => job.id,
      "allow_failure"         => job.allow_failure,
      "number"                => job.number,
      "state"                 => job.state,
      "started_at"            => "2010-11-12T12:00:00Z",
      "finished_at"           => "2010-11-12T12:00:10Z",
      "build"                 => {
        "@type"               => "build",
        "@href"               => "/v3/build/#{build.id}",
        "@representation"     => "minimal",
        "id"                  => build.id,
        "number"              => build.number,
        "state"               => build.state,
        "duration"            => build.duration,
        "event_type"          => build.event_type,
        "previous_state"      => build.previous_state,
        "pull_request_number" => build.pull_request_number,
        "pull_request_title"  => build.pull_request_title,
        "started_at"          => "2010-11-12T12:00:00Z",
        "finished_at"         => "2010-11-12T12:00:10Z"},
      "stage"                 => {
        "@type"               => "stage",
        "@representation"     => "minimal",
        "id"                  => stage.id,
        "number"              => 1,
        "name"                => "test",
        "state"               => stage.state,
        "started_at"          => stage.started_at,
        "finished_at"         => stage.finished_at},
      "queue"                 => job.queue,
      "repository"            => {
        "@type"               => "repository",
        "@href"               => "/v3/repo/#{repo.id}",
        "@representation"     => "minimal",
        "id"                  => repo.id,
        "name"                => repo.name,
        "slug"                => repo.slug},
      "commit"                => {
        "@type"               => "commit",
        "@representation"     => "minimal",
        "id"                  => commit.id,
        "sha"                 => commit.commit,
        "ref"                 => commit.ref,
        "message"             => commit.message,
        "compare_url"         => commit.compare_url,
        "committed_at"        => "2010-11-12T11:50:00Z"},
      "owner"                 => {
        "@type"               => owner_type.to_s.downcase,
        "@href"               => "/v3/#{owner_href}/#{owner.id}",
        "@representation"     => "minimal",
        "id"                  => owner.id,
        "login"               => owner.login},
      "config"                => {
        "rvm"                 =>"1.9.2",
        "gemfile"             =>"test/Gemfile.rails-3.0.x",
        "language"            =>"ruby",
        "group"               =>"stable",
        "dist"                =>"precise",
        "os"                  =>"linux"}
    }}
  end

  describe "config correctly serialized" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: false) }
    before     { get("/v3/job/#{job2.id}")     }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
      "@type"                 => "job",
      "@href"                 => "/v3/job/#{job2.id}",
      "@representation"       => "standard",
      "@permissions"          => {
        "read"                => true,
        "cancel"              => false,
        "restart"             => false,
        "debug"               => false,
        "delete_log"          => false },
      "id"                    => job.id,
      "allow_failure"         => job.allow_failure,
      "number"                => job.number,
      "state"                 => job.state,
      "started_at"            => "2010-11-12T12:00:00Z",
      "finished_at"           => "2010-11-12T12:00:10Z",
      "build"                 => {
        "@type"               => "build",
        "@href"               => "/v3/build/#{build.id}",
        "@representation"     => "minimal",
        "id"                  => build.id,
        "number"              => build.number,
        "state"               => build.state,
        "duration"            => build.duration,
        "event_type"          => build.event_type,
        "previous_state"      => build.previous_state,
        "pull_request_number" => build.pull_request_number,
        "pull_request_title"  => build.pull_request_title,
        "started_at"          => "2010-11-12T12:00:00Z",
        "finished_at"         => "2010-11-12T12:00:10Z"},
      "stage"                 => {
        "@type"               => "stage",
        "@representation"     => "minimal",
        "id"                  => stage.id,
        "number"              => 1,
        "name"                => "test",
        "state"               => stage.state,
        "started_at"          => stage.started_at,
        "finished_at"         => stage.finished_at},
      "queue"                 => job.queue,
      "repository"            => {
        "@type"               => "repository",
        "@href"               => "/v3/repo/#{repo.id}",
        "@representation"     => "minimal",
        "id"                  => repo.id,
        "name"                => repo.name,
        "slug"                => repo.slug},
      "commit"                => {
        "@type"               => "commit",
        "@representation"     => "minimal",
        "id"                  => commit.id,
        "sha"                 => commit.commit,
        "ref"                 => commit.ref,
        "message"             => commit.message,
        "compare_url"         => commit.compare_url,
        "committed_at"        => "2010-11-12T11:50:00Z"},
      "owner"                 => {
        "@type"               => owner_type.to_s.downcase,
        "@href"               => "/v3/#{owner_href}/#{owner.id}",
        "@representation"     => "minimal",
        "id"                  => owner.id,
        "login"               => owner.login},
      "config"                => {
        "foo"                 => "bar",
        "env"                 => {
          "BAR"               => "[secure] [secure]",
          "FOO"               => "foo" }}
    }}
  end
end
