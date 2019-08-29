describe Travis::API::V3::Services::Repositories::ForOwner, set_app: true do
  include Support::Formats
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:jobs)  { Travis::API::V3::Models::Build.find(build.id).jobs }

  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
  before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
  before        { repo.update_attribute(:private, true)                             }
  before        { repo.update_attribute(:current_build, build)                             }
  after         { repo.update_attribute(:private, false)                            }

  describe "sorting by default_branch.last_build" do
    let!(:repo2) { Travis::API::V3::Models::Repository.create!(owner_name: 'svenfuchs', owner: repo.owner, name: 'second-repo', default_branch_name: 'other-branch') }
    let!(:branch) { repo2.default_branch }
    let!(:build) { Travis::API::V3::Models::Build.create(repository: repo2, branch_id: branch.id, branch_name: 'other-branch') }

    before do
      branch.update_attributes!(last_build_id: build.id)
      Travis::API::V3::Models::Permission.create(repository: repo2, user: repo2.owner, pull: true)
      get("/v3/owner/svenfuchs/repos?sort_by=default_branch.last_build:desc&include=repository.default_branch", {}, headers)
    end

    example { expect(last_response).to be_ok }
    example 'repos with most recent build on default branch come first' do
      repos = JSON.load(last_response.body)['repositories']
      last_build_ids = repos.map { |r| r['default_branch']['last_build']['id'] }
      expect(last_build_ids).to eq last_build_ids.sort.reverse
    end
  end

  describe "private repository, private API, authenticated as user with access" do
    before  { get("/v3/owner/svenfuchs/repos", {}, headers) }
    example { expect(last_response).to be_ok }
    example { expect(JSON.load(body)).to be == {
      "@type"                => "repositories",
      "@href"                => "/v3/owner/svenfuchs/repos",
      "@representation"      => "standard",
      "@pagination"          => {
        "limit"              => 100,
        "offset"             => 0,
        "count"              => 1,
        "is_first"           => true,
        "is_last"            => true,
        "next"               => nil,
        "prev"               => nil,
        "first"              => {
          "@href"            => "/v3/owner/svenfuchs/repos",
          "offset"           => 0,
          "limit"            => 100},
          "last"             => {
            "@href"          => "/v3/owner/svenfuchs/repos",
            "offset"         => 0,
            "limit"          => 100}},
      "repositories"         => [{
        "@type"              => "repository",
        "@href"              => "/v3/repo/#{repo.id}",
        "@representation"    => "standard",
        "@permissions"       => {
          "read"             => true,
          "activate"         => false,
          "deactivate"       => false,
          "migrate"          => false,
          "star"             => true,
          "unstar"           => true,
          "create_request"   => false,
          "create_cron"      => false,
          "create_env_var"   => false,
          "create_key_pair"  => false,
          "delete_key_pair"  => false,
          "admin"            => false
        },
        "id"                 => repo.id,
        "name"               => "minimal",
        "slug"               => "svenfuchs/minimal",
        "description"        => nil,
        "github_id"          => repo.github_id,
        "vcs_id"             => repo.vcs_id,
        "vcs_type"           => "GithubRepository",
        "github_language"    => nil,
        "active"             => true,
        "private"            => true,
        "owner"              => {
          "@type"            => "user",
          "id"               => repo.owner_id,
          "login"            => "svenfuchs",
          "@href"            => "/v3/user/#{repo.owner_id}" },
        "default_branch"     => {
          "@type"            => "branch",
          "@href"            => "/v3/repo/#{repo.id}/branch/master",
          "@representation"  => "minimal",
          "name"             => "master"},
          "starred"          => false,
          "managed_by_installation"=>false,
          "active_on_org"    => nil,
          "migration_status" => nil,
          "history_migration_status"  => nil
        }]}}
  end

  describe "include: last_started_build" do
    before  { get("/v3/owner/svenfuchs/repos?include=repository.last_started_build", {}, headers)                           }
    example { expect(last_response)                   .to be_ok                                      }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/owner/svenfuchs/repos?include=repository.last_started_build"}
    example { expect(JSON.load(body)['repositories']) .to be == [{
        "@type"              =>"repository",
        "@href"              =>"/v3/repo/#{repo.id}",
        "@representation"    =>"standard",
        "@permissions"       =>{
          "read"             =>true,
          "admin"            =>false,
          "activate"         =>false,
          "deactivate"       =>false,
          "migrate"          => false,
          "star"             =>true,
          "unstar"           =>true,
          "create_cron"      =>false,
          "create_env_var"   =>false,
          "create_key_pair"  =>false,
          "delete_key_pair"  =>false,
          "create_request"   =>false},
        "id"                 =>repo.id,
        "name"               =>"minimal",
        "slug"               =>"svenfuchs/minimal",
        "description"        =>nil,
        "github_id"          =>repo.github_id,
        "vcs_id"             => repo.vcs_id,
        "vcs_type"           => "GithubRepository",
        "github_language"    =>nil,
        "active"             =>true,
        "private"            =>true,
        "owner"              =>{
          "@type"            =>"user",
          "id"               =>1,
          "login"            =>"svenfuchs",
          "@href"            =>"/v3/user/1"},
        "default_branch"     =>{
          "@type"            =>"branch",
          "@href"            =>"/v3/repo/1/branch/master",
          "@representation"  =>"minimal",
          "name"             =>"master"},
        "starred"          =>false,
        "managed_by_installation"=>false,
        "active_on_org"     => nil,
        "migration_status"  => nil,
        "history_migration_status"  => nil,
        "last_started_build"=>{
          "@type"          =>"build",
          "@href"          =>"/v3/build/#{build.id}",
          "@representation"=>"standard",
          "@permissions"   =>{
            "read"         =>true,
            "cancel"       =>true,
            "restart"      =>true},
          "id"             =>build.id,
          "number"         =>"#{build.number}",
          "state"          =>"configured",
          "duration"       =>nil,
          "event_type"     =>"push",
          "previous_state" =>"passed",
          "pull_request_title"=>nil,
          "pull_request_number"=>nil,
          "started_at"     =>"2010-11-12T13:00:00Z",
          "finished_at"    =>nil,
          "private"        => false,
          "repository"    =>{
            "@href"       =>"/v3/repo/#{repo.id}"},
          "branch"        =>{
            "@type"       =>"branch",
            "@href"       =>"/v3/repo/1/branch/master",
            "@representation"=>"minimal",
            "name"        =>"master"},
          "tag"           =>nil,
          "commit"        =>{
            "@type"       =>"commit",
            "@representation"=>"minimal",
            "id"          =>5,
            "sha"         =>"add057e66c3e1d59ef1f",
            "ref"         => "refs/heads/master",
            "message"     =>"unignore Gemfile.lock",
            "compare_url" =>"https://github.com/svenfuchs/minimal/compare/master...develop",
            "committed_at"=>"2010-11-12T12:55:00Z"},
          "jobs"          =>[{
            "@type"       =>"job",
            "@href"       =>"/v3/job/#{jobs[0].id}",
            "@representation"=>"minimal",
            "id"          =>jobs[0].id}, {
            "@type"       =>"job",
            "@href"       =>"/v3/job/#{jobs[1].id}",
            "@representation"=>"minimal",
            "id"          =>jobs[1].id}, {
            "@type"       =>"job",
            "@href"       =>"/v3/job/#{jobs[2].id}",
            "@representation"=>"minimal",
            "id"          =>jobs[2].id}, {
            "@type"       =>"job",
            "@href"       =>"/v3/job/#{jobs[3].id}",
            "@representation"=>"minimal",
            "id"          =>jobs[3].id}],
          "stages"        =>[],
          "created_by"    =>nil,
          "updated_at"    => json_format_time_with_ms(build.updated_at)}}]}
  end

  describe "include: current_build" do
    before  { get("/v3/owner/svenfuchs/repos?include=repository.current_build", {}, headers)                           }
    example { expect(last_response)                   .to be_ok                                      }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/owner/svenfuchs/repos?include=repository.current_build"}
    example { expect(JSON.load(body)['@warnings'])    .to be == [{
        "@type"              => "warning",
        "message"            => "current_build will soon be deprecated. Please use repository.last_started_build instead",
        "warning_type"       => "deprecated_parameter",
        "parameter"          => "current_build"}]}
    example { expect(JSON.load(body)['repositories']) .to be == [{
        "@type"              => "repository",
        "@href"              => "/v3/repo/#{repo.id}",
        "@representation"    => "standard",
        "@permissions"       => {
          "read"             => true,
          "admin"            => false,
          "activate"         => false,
          "deactivate"       => false,
          "migrate"          => false,
          "star"             => true,
          "unstar"           => true,
          "create_cron"      => false,
          "create_env_var"   => false,
          "create_key_pair"  => false,
          "delete_key_pair"  => false,
          "create_request"   => false},
        "id"                 => repo.id,
        "name"               => "minimal",
        "slug"               => "svenfuchs/minimal",
        "description"        => nil,
        "github_id"          => repo.github_id,
        "vcs_id"             => repo.vcs_id,
        "vcs_type"           => "GithubRepository",
        "github_language"    => nil,
        "active"             => true,
        "private"            => true,
        "owner"              => {
          "@type"            => "user",
          "id"               => 1,
          "login"            => "svenfuchs",
          "@href"            => "/v3/user/1"},
        "default_branch"     => {
          "@type"            => "branch",
          "@href"            => "/v3/repo/1/branch/master",
          "@representation"  => "minimal",
          "name"             => "master"},
        "starred"          => false,
        "managed_by_installation"=> false,
        "active_on_org"    => nil,
        "migration_status" => nil,
        "history_migration_status"  => nil,
        "current_build" => {
          "@type"               => "build",
          "@href"               => "/v3/build/#{build.id}",
          "@representation"     => "standard",
          "@permissions"        => {
            "read"    => true,
            "cancel"  => true,
            "restart" => true
          },
          "id"                  => build.id,
          "number"              => "#{build.number}",
          "state"               => "configured",
          "duration"            => nil,
          "event_type"          => "push",
          "previous_state"      => "passed",
          "pull_request_title"  => nil,
          "pull_request_number" => nil,
          "started_at"     => "2010-11-12T13:00:00Z",
          "finished_at"    => nil,
          "private"        => false,
          "repository"     => {
            "@href"       => "/v3/repo/#{repo.id}"
          },
          "branch"        => {
            "@type"           => "branch",
            "@href"           => "/v3/repo/1/branch/master",
            "@representation" => "minimal",
            "name"            => "master"
          },
          "tag"           => nil,
          "commit"        => {
            "@type"           => "commit",
            "@representation" => "minimal",
            "id"              => 5,
            "sha"             => "add057e66c3e1d59ef1f",
            "ref"             => "refs/heads/master",
            "message"         => "unignore Gemfile.lock",
            "compare_url"     => "https://github.com/svenfuchs/minimal/compare/master...develop",
            "committed_at"    => "2010-11-12T12:55:00Z"
          },
          "jobs"          => [
            {
              "@type"           => "job",
              "@href"           => "/v3/job/#{jobs[0].id}",
              "@representation" => "minimal",
              "id"              => jobs[0].id
            }, {
              "@type"           => "job",
              "@href"           => "/v3/job/#{jobs[1].id}",
              "@representation" => "minimal",
              "id"              => jobs[1].id
            }, {
              "@type"           => "job",
              "@href"           => "/v3/job/#{jobs[2].id}",
              "@representation" => "minimal",
              "id"              => jobs[2].id
            }, {
              "@type"           => "job",
              "@href"           => "/v3/job/#{jobs[3].id}",
              "@representation" => "minimal",
              "id"              => jobs[3].id
            }
          ],
          "stages"        => [],
          "created_by"    => nil,
          "updated_at"    => json_format_time_with_ms(build.updated_at)}}]}
  end

  describe "filter: private=false" do
    before  { get("/v3/repos", {"repository.private" => "false"}, headers)                           }
    example { expect(last_response)                   .to be_ok                                      }
    example { expect(JSON.load(body)['repositories']) .to be == []                                   }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/repos?repository.private=false" }
  end

  describe "filter: active=false" do
    before  { get("/v3/repos", {"repository.active" => "false"}, headers)  }
    example { expect(last_response)                   .to be_ok            }
    example { expect(JSON.load(body)['repositories']) .to be == []         }
  end

  describe "filter: starred=true" do
    before  { Travis::API::V3::Models::Star.create(user: repo.owner, repository: repo)   }
    before  { get("/v3/repos", {"starred" => "true"}, headers)                           }
    after   { repo.owner.stars.each(&:destroy)                                           }
    example { expect(last_response)                   .to be_ok                          }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/repos?starred=true" }
    example { expect(JSON.load(body)['repositories']) .not_to be_empty                   }
  end

  describe "filter: starred=false" do
    before  { get("/v3/repos", {"starred" => "false"}, headers)                              }
    example { expect(last_response)                   .to be_ok                              }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/repos?starred=false"    }
    example { expect(JSON.load(body)['repositories']) .not_to be_empty                       }
  end

  describe "filter: starred=false but no unstarred repos" do
    before  { Travis::API::V3::Models::Star.create(user: repo.owner, repository: repo)       }
    after   { repo.owner.stars.each(&:destroy)                                               }
    before  { get("/v3/repos", {"starred" => "false"}, headers)                              }
    example { expect(last_response)                   .to be_ok                              }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/repos?starred=false"    }
    example { expect(JSON.load(body)['repositories']) .to be_empty                           }
  end

  describe "sorting by default_branch.last_build" do
    let(:repo2)  { Travis::API::V3::Models::Repository.create(owner_name: 'svenfuchs', name: 'maximal', owner_id: 1, owner_type: "User", last_build_state: "passed", active: true, next_build_number: 3, vcs_type: 'GithubRepository') }
    before  { repo2.save! }
    before  { get("/v3/owner/svenfuchs/repos?sort_by=default_branch.last_build", {}, headers) }
    example { expect(last_response).to be_ok }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/owner/svenfuchs/repos?sort_by=default_branch.last_build" }
    example { expect(JSON.load(body)['repositories'])   .to be == [{
        "@type"           => "repository",
        "@href"           => "/v3/repo/1",
        "@representation" => "standard",
        "@permissions"    => {
          "read"          => true,
          "admin"         => false,
          "activate"      => false,
          "deactivate"    => false,
          "migrate"       => false,
          "star"          => true,
          "unstar"        => true,
          "create_cron"   => false,
          "create_env_var" => false,
          "create_key_pair"=> false,
          "delete_key_pair"=> false,
          "create_request"=> false
        },
        "id"              => 1,
        "name"            => "minimal",
        "slug"            => "svenfuchs/minimal",
        "description"     => nil,
        "github_id"       => repo.github_id,
        "vcs_id"          => repo.vcs_id,
        "vcs_type"        => "GithubRepository",
        "github_language" => nil,
        "active"          => true,
        "private"         => true,
        "owner"           => {
          "@type"         => "user",
          "id"            => 1,
          "login"         => "svenfuchs",
          "@href"         => "/v3/user/1" },
        "default_branch"  => {
          "@type"         => "branch",
          "@href"         => "/v3/repo/1/branch/master",
          "@representation"=>"minimal",
          "name"          => "master" },
        "starred"         => false,
        "managed_by_installation"=>false,
        "active_on_org"   => nil,
        "migration_status" => nil,
        "history_migration_status"  => nil}, {
        "@type"           => "repository",
        "@href"           => "/v3/repo/#{repo2.id}",
        "@representation" => "standard",
        "@permissions"    => {
          "read"          => true,
          "admin"         => false,
          "activate"      => false,
          "deactivate"    => false,
          "migrate"       => false,
          "star"          => false,
          "unstar"        => false,
          "create_cron"   => false,
          "create_env_var"  => false,
          "create_key_pair" => false,
          "delete_key_pair"  => false,
          "create_request"=> false
        },
        "id"              => repo2.id,
        "name"            => "maximal",
        "slug"            => "svenfuchs/maximal",
        "description"     => nil,
        "github_id"       => repo2.github_id,
        "vcs_id"          => repo2.vcs_id,
        "vcs_type"        => "GithubRepository",
        "github_language" => nil,
        "active"          => true,
        "private"         => false,
        "owner"           => {
          "@type"         => "user",
          "id"            => 1,
          "login"         => "svenfuchs",
          "@href"         => "/v3/user/1" },
        "default_branch"  => {
          "@type"         => "branch",
          "@href"         => "/v3/repo/#{repo2.id}/branch/master",
          "@representation"=>"minimal",
          "name"           =>"master" },
          "starred"        => false,
          "managed_by_installation"=>false,
          "active_on_org"  =>nil,
          "migration_status" => nil,
          "history_migration_status" => nil}]}
  end
end
