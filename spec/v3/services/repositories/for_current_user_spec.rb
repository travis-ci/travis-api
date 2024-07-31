describe Travis::API::V3::Services::Repositories::ForCurrentUser, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:jobs)  { Travis::API::V3::Models::Build.find(build.id).jobs }

  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)             }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                                    }}
  before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, push: true, admin: true) }
  before        { repo.update_attribute(:private, true)                                         }
  after         { repo.update_attribute(:private, false)                                        }
  before        { Travis::Features.activate_owner(:allow_migration, repo.owner) }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  let(:authorization_role) { { 'roles' => ['repository_admin'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }
  before { stub_request(:get, %r((.+)/roles/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization_role)) }
  before { stub_request(:post, %r((.+)/permissions/repositories)).to_return(status: 400) }
  before { stub_request(:post, %r((.+)/roles/repositories)).to_return(status: 400) }

  describe "private repository, private API, authenticated as user with access" do
    before  { get("/v3/repos", {}, headers)    }
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"                => "repositories",
      "@href"                => "/v3/repos",
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
          "@href"            => "/v3/repos",
          "offset"           => 0,
          "limit"            => 100},
          "last"             => {
            "@href"          => "/v3/repos",
            "offset"         => 0,
            "limit"          => 100}},
      "repositories"         => [{
        "@type"              => "repository",
        "@href"              => "/v3/repo/#{repo.id}",
        "@representation"    => "standard",
        "@permissions"       => {
          "read"             => true,
          "activate"         => true,
          "deactivate"       => true,
          "migrate"          => true,
          "star"             => true,
          "unstar"           => true,
          "create_request"   => true,
          "create_cron"      => true,
          "create_env_var"   => true,
          "create_key_pair"  => true,
          "delete_key_pair"  => true,
          "check_scan_results" => true,
          "admin"            => true,
          "build_cancel"     =>true,
          "build_create"     =>true,
          "build_debug"      =>true,
          "build_restart"    =>true,
          "cache_delete"     =>true,
          "cache_view"       =>true,
          "settings_create"  =>true,
          "settings_delete"  =>true,
          "settings_read"    =>true,
          "settings_update"  =>true,
          "log_delete"       =>true,
          "log_view"         =>true
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
        "server_type"        => 'git',
        "shared"             => false,
        "scan_failed_at"     => nil,
        "owner"              => {
          "@type"            => "user",
          "@href"            => "/v3/user/#{repo.owner_id}",
          "id"               => repo.owner_id,
          "ro_mode"          => true,
          "login"            => "svenfuchs" },
        "default_branch"     => {
          "@type"            => "branch",
          "@href"            => "/v3/repo/#{repo.id}/branch/master",
          "@representation"  => "minimal",
          "name"             => "master"},
        "starred"            => false,
        "managed_by_installation"=>false,
        "active_on_org"=>nil,
        "migration_status" => nil,
        "history_migration_status" => nil,
        "config_validation" => false
        }]
    }}
  end

  describe "don't nest list of repositories inside a list of repositories even if the user asks for it. user has no idea what they are doing" do
    before  { get("/v3/repos?include=user.repositories", {}, headers)                          }
    example { expect(last_response).to be_ok                                                   }
    example { expect(JSON.load(body)['repositories'].first['owner']['repositories']).to be_nil }
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

  describe "filter: managed_by_installation=true" do
    before  { get("/v3/repos", {"managed_by_installation" => "true"}, headers)                               }
    example { expect(last_response)                   .to be_ok                                              }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/repos?managed_by_installation=true"     }
    example { expect(JSON.load(body)['repositories']) .to be_empty                                           }
  end

  describe "filter: managed_by_installation=false" do
    before  { get("/v3/repos", {"managed_by_installation" => "false"}, headers)                              }
    example { expect(last_response)                   .to be_ok                                              }
    example { expect(JSON.load(body)['@href'])        .to be == "/v3/repos?managed_by_installation=false"    }
    example { expect(JSON.load(body)['repositories']) .not_to be_empty                                       }
  end

  describe "include: repository.email_subscribed" do
    subject(:response)  { get("/v3/repos", {"include" => "repository.email_subscribed"}, headers)                           }

    example do
      expect(response).to be_ok
      expect(JSON.load(body)['repositories'].first['email_subscribed']).to eq(true)
    end

    context 'when the current user is unsubscribed' do
      before do
        delete("/v3/repo/#{repo.id}/email_subscription", {}, headers)
      end

      example do
        expect(response).to be_ok
        expect(JSON.load(body)['repositories'].first['email_subscribed']).to eq(false)
      end
    end
  end
end
