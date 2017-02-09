describe Travis::API::V3::Services::Job::Find, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:owner_href)  { repo.owner_type.downcase }
  let(:owner_type)  { repo.owner_type.constantize }
  let(:owner)       { owner_type.find(repo.owner_id)}
  let(:build)       { repo.builds.last }
  let(:default_branch) { repo.default_branch}
  let(:def_branch_jobs){ Travis::API::V3::Models::Build.find(default_branch.last_build.id).jobs}
  let(:jobs)        { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:job)         { Travis::API::V3::Models::Build.find(build.id).jobs.last }
  let(:commit)      { job.commit }
  let(:parsed_body) { JSON.load(body) }

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
        "@type"               => owner_type.to_s[/[^:]+$/].downcase,
        "@href"               => "/v3/#{owner_href}/#{owner.id}",
        "@representation"     => "minimal",
        "id"                  => owner.id,
        "login"               => owner.login}
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
        "@type"               => owner_type.to_s[/[^:]+$/].downcase,
        "@href"               => "/v3/#{owner_href}/#{owner.id}",
        "@representation"     => "minimal",
        "id"                  => owner.id,
        "login"               => owner.login}
    }}
  end
end
