describe Travis::API::V3::Services::Repositories::ForOwner, set_app: true, billing_spec_helper: true do
  include Support::Formats
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:sharedrepo)  { Travis::API::V3::Models::Repository.where(owner_name: 'sharedrepoowner', name: 'sharedrepo').first }
  let(:build) { repo.builds.first }
  let(:jobs)  { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}

  let(:token_collaborator)   { Travis::Api::App::AccessToken.create(user: Travis::API::V3::Models::User.find_by_login('johndoe'), app_id: 1) }
  let(:headers_collaborator) {{ 'HTTP_AUTHORIZATION' => "token #{token_collaborator}"                        }}
  before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
  before        { repo.update_attribute(:private, true)                             }
  before        { repo.update_attribute(:current_build, build)                             }
  after         { repo.update_attribute(:private, false)                            }
  before        { RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 1024*1024 }

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
        "vcs_type"           => repo.vcs_type,
        "owner_name"         => "svenfuchs",
        "vcs_name"           => "minimal",
        "github_language"    => nil,
        "active"             => true,
        "private"            => true,
        "shared"             => false,
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
          "history_migration_status"  => nil,
          "config_validation" => false
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
        "vcs_type"           => repo.vcs_type,
        "owner_name"         => "svenfuchs",
        "vcs_name"           => "minimal",
        "github_language"    =>nil,
        "active"             =>true,
        "private"            =>true,
        "shared"             =>false,
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
        "config_validation" => false,
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
        "vcs_type"           => repo.vcs_type,
        "owner_name"         => "svenfuchs",
        "vcs_name"           => "minimal",
        "github_language"    => nil,
        "active"             => true,
        "private"            => true,
        "shared"             => false,
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
        "config_validation" => false,
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
    let(:repo2)  { Travis::API::V3::Models::Repository.create(owner_name: 'svenfuchs', name: 'maximal', owner_id: 1, owner_type: "User", last_build_state: "passed", active: true, next_build_number: 3) }
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
        "vcs_type"        => repo.vcs_type,
        "owner_name"      => "svenfuchs",
        "vcs_name"        => "minimal",
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
        "shared"          => false,
        "managed_by_installation"=>false,
        "active_on_org"   => nil,
        "migration_status" => nil,
        "history_migration_status"  => nil,
        "config_validation" => false}, {
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
        "vcs_type"        => repo2.vcs_type,
        "owner_name"      => "svenfuchs",
        "vcs_name"        => "maximal",
        "github_language" => nil,
        "active"          => true,
        "private"         => false,
        "shared"          => false,
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
          "history_migration_status" => nil,
          "config_validation" => false}]}
  end

  describe "shared repository for collaborator, authenticated as user with access" do
    before  { get("/v3/owner/johndoe/repos", {}, headers_collaborator) }
    example { expect(last_response).to be_ok }
    example { expect(JSON.load(body)).to be == {
      "@type"                => "repositories",
      "@href"                => "/v3/owner/johndoe/repos",
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
          "@href"            => "/v3/owner/johndoe/repos",
          "offset"           => 0,
          "limit"            => 100},
          "last"             => {
            "@href"          => "/v3/owner/johndoe/repos",
            "offset"         => 0,
            "limit"          => 100}},
      "repositories"         => [{
        "@type"              => "repository",
        "@href"              => "/v3/repo/#{sharedrepo.id}",
        "@representation"    => "standard",
        "@permissions"       => {
          "read"             => true,
          "activate"         => true,
          "deactivate"       => true,
          "migrate"          => false,
          "star"             => true,
          "unstar"           => true,
          "create_request"   => true,
          "create_cron"      => true,
          "create_env_var"   => true,
          "create_key_pair"  => true,
          "delete_key_pair"  => true,
          "admin"            => false
        },
        "id"                 => sharedrepo.id,
        "name"               => "sharedrepo",
        "slug"               => "sharedrepoowner/sharedrepo",
        "description"        => nil,
        "github_id"          => sharedrepo.github_id,
        "vcs_id"             => sharedrepo.vcs_id,
        "vcs_type"           => sharedrepo.vcs_type,
        "owner_name"         => "sharedrepoowner",
        "vcs_name"           => "sharedrepo",
        "github_language"    => nil,
        "active"             => true,
        "private"            => false,
        "shared"             => true,
        "owner"              => {
          "@type"            => "user",
          "id"               => sharedrepo.owner_id,
          "login"            => "sharedrepoowner",
          "@href"            => "/v3/user/#{sharedrepo.owner_id}" },
        "default_branch"     => {
          "@type"            => "branch",
          "@href"            => "/v3/repo/#{sharedrepo.id}/branch/master",
          "@representation"  => "minimal",
          "name"             => "master"},
          "starred"          => false,
          "managed_by_installation"=>false,
          "active_on_org"    => nil,
          "migration_status" => nil,
          "history_migration_status"  => nil,
          "config_validation" => false
        }]}}
  end

  describe "allowance, org" do
    before  { get("/v3/owner/svenfuchs/allowance", {}, headers) }
    example { expect(last_response).to be_ok }
    example { expect(JSON.load(body)).to be == {
      "@representation"       => "standard",
      "@type"                 => "allowance",
      "concurrency_limit"     => 1,
      "private_repos"         => false,
      "public_repos"          => true,
      "subscription_type"     => 1,
      "user_usage"            => false,
      "pending_user_licenses" => false,
      "id"                    => 0
    }}
  end

  describe "allowance, com" do
    before do
      Travis.config.host = 'travis-ci.com'
      Travis.config.billing.url = billing_url
      Travis.config.billing.auth_key = billing_auth_key
      stub_billing_request(:get, "/usage/users/1/allowance", auth_key: billing_auth_key, user_id: 1)
        .to_return(body: JSON.dump({ 'public_repos': true, 'private_repos': true, 'user_usage': true, 'pending_user_licenses': false, 'concurrency_limit': 666 }))
      get("/v3/owner/svenfuchs/allowance", {}, headers)
    end
    example { expect(last_response).to be_ok }
    example { expect(JSON.load(body)).to be == {
      "@representation"       => "standard",
      "@type"                 => "allowance",
      "concurrency_limit"     => 666,
      "private_repos"         => true,
      "public_repos"          => true,
      "subscription_type"     => 2,
      "user_usage"            => true,
      "pending_user_licenses" => false,
      "id"                    => 1
    }}
  end

  describe "allowance with bad owner, com" do
    before do
      Travis.config.host = 'travis-ci.com'
      Travis.config.billing.url = billing_url
      Travis.config.billing.auth_key = billing_auth_key
      get("/v3/owner/another/allowance", {}, headers)
    end
    example { expect(last_response.status).to eq(404) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'error',
        'error_type' => 'not_found',
        'error_message' => 'resource not found (or insufficient access)'
      )
    end
  end
end
