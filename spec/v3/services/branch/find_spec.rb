describe Travis::API::V3::Services::Branch::Find, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }

  before { repo.default_branch.save! }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe "public repository, existing branch" do
    before     { get("/v3/repo/#{repo.id}/branch/master") }
    example    { expect(last_response).to be_ok           }
    example    { expect(JSON.load(body)).to be == {
      "@type"            => "branch",
      "@href"            => "/v3/repo/#{repo.id}/branch/master",
      "@representation"  => "standard",
      "name"             => "master",
      "default_branch"   => true,
      "exists_on_github" => true,
      "repository"       => {
        "@type"          => "repository",
        "@href"          => "/v3/repo/#{repo.id}",
        "@representation"=> "minimal",
        "id"             => repo.id,
        "name"           => "minimal",
        "slug"           => "svenfuchs/minimal"},
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
        "private"        => false,
        "priority"       => false,
        "pull_request_number" => build.pull_request_number,
        "pull_request_title" => build.pull_request_title,
        "started_at"     => "2010-11-12T13:00:00Z",
        "finished_at"    => nil }}}
  end

  describe "including recent_builds" do
    before     { get("/v3/repo/#{repo.id}/branch/master?include=branch.recent_builds") }
    example    { expect(last_response).to be_ok }
    example    { expect(JSON.load(body)).to include('recent_builds')}
  end
end
