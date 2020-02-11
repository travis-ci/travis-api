describe Travis::API::V3::Services::Branch::Find, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }

  describe "public repository, existing branch" do
    before     { get("/v3/repo/1/branch/master") }
    example    { expect(last_response).to be_ok }
    example    { expect(JSON.load(body)).to be == {
      "@type"            => "branch",
      "@href"            => "/v3/repo/1/branch/master",
      "@representation"  => "standard",
      "name"             => "master",
      "exists_on_github" => true,
      "default_branch"   => true,
      "repository"       => {
        "@type"          => "repository",
        "@href"          => "/repo/1",
        "@representation"=> "standard",
        "@permissions"   => {
          "read"           => true,
          "admin"          => false,
          "delete_key_pair"=> false,
          "create_request" => false,
          "activate"       => false,
          "deactivate"     => false,
          "migrate"        => false,
          "star"           => false,
          "unstar"         => false,
          "create_cron"    => false,
          "create_env_var" => false,
          "create_key_pair"=> false
        },
        "id"                       => repo.id,
        "name"                     => "minimal",
        "slug"                     => "svenfuchs/minimal",
        "description"              => nil,
        "github_id"                => repo.id,
        "vcs_id"                   => nil,
        "vcs_type"                 => "GithubRepository",
        "github_language"          => nil,
        "active"                   => true,
        "private"                  => false,
        "owner"                    => {
          "@type"                    => "user",
          "id"                       => 1,
          "login"                    => "svenfuchs",
          "@href"                    => "/user/1"
        },
        "default_branch"           => {
          "@type"                    => "branch",
          "@href"                    => "/repo/#{repo.id}/branch/master",
          "@representation"          => "minimal",
          "name"                     => "master"
        },
        "starred"                  =>false,
        "managed_by_installation"  => false,
        "active_on_org"            => nil,
        "migration_status"         => nil,
        "history_migration_status" => nil
      },
      "last_build"          => {
        "@type"               => "build",
        "@href"               => "/v3/build/#{build.id}",
        "@representation"     => "minimal",
        "id"                  => build.id,
        "number"              => build.number,
        "state"               => build.state,
        "duration"            => nil,
        "event_type"          => "push",
        "previous_state"      => "passed",
        "private"             => false,
        "pull_request_number" => build.pull_request_number,
        "pull_request_title"  => build.pull_request_title,
        "started_at"          => "2010-11-12T13:00:00Z",
        "finished_at"         => nil 
      }
    }
  }
  end

  describe "including recent_builds" do
    before     { get("/v3/repo/#{repo.id}/branch/master?include=branch.recent_builds") }
    example    { expect(last_response).to be_ok }
    example    { expect(JSON.load(body)).to include('recent_builds')}
  end
end
