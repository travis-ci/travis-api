describe Travis::API::V3::Services::Repository::Find, set_app: true do
  let(:user) { User.where(login: 'svenfuchs').first }
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:jobs)  { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:parsed_body) { JSON.load(body) }

  describe "fetching a public repository by slug" do
    before     { get("/v3/repo/svenfuchs%2Fminimal")     }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body['slug']).to be == 'svenfuchs/minimal' }
  end

  describe "fetching a non-existing repository by slug" do
    before     { get("/v3/repo/svenfuchs%2Fminimal1")     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "public repository" do
    before     { get("/v3/repo/#{repo.id}")     }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
      "@type"              => "repository",
      "@href"              => "/v3/repo/#{repo.id}",
      "@representation"    => "standard",
      "@permissions"       => {
        "read"             => true,
        "activate"         => false,
        "deactivate"       => false,
        "star"             => false,
        "unstar"           => false,
        "create_request"   => false,
        "create_cron"      => false,
        "change_env_vars"  => false,
        "change_key"       => false,
        "admin"            => false
      },
      "id"                 =>  repo.id,
      "name"               =>  "minimal",
      "slug"               =>  "svenfuchs/minimal",
      "description"        => nil,
      "github_language"    => nil,
      "active"             => true,
      "private"            => false,
      "owner"              => {
        "id"               => repo.owner_id,
        "login"            => "svenfuchs",
        "@type"            => "user",
        "@href"            => "/v3/user/#{repo.owner_id}"},
      "default_branch"     => {
        "@type"            => "branch",
        "@href"            => "/v3/repo/#{repo.id}/branch/master",
        "@representation"  => "minimal",
        "name"             => "master"},
      "starred"            => false,
    }}
  end

  describe "missing repository" do
    before  { get("/v3/repo/999999999999999")       }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "public repository, private API" do
    before  { Travis.config.private_api = true      }
    before  { get("/v3/repo/#{repo.id}")            }
    after   { Travis.config.private_api = false     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "private repository, not authenticated" do
    before  { repo.update_attribute(:private, true)  }
    before  { get("/v3/repo/#{repo.id}")             }
    before  { repo.update_attribute(:private, false) }
    example { expect(last_response).to be_not_found  }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, admin: false) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}", {}, headers)                           }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(parsed_body).to be == {
      "@type"              => "repository",
      "@href"              => "/v3/repo/#{repo.id}",
      "@representation"    => "standard",
      "@permissions"       => {
        "read"             => true,
        "activate"         => false,
        "deactivate"       => false,
        "star"             => false,
        "unstar"           => false,
        "create_request"   => false,
        "create_cron"      => false,
        "change_env_vars"  => false,
        "change_key"       => false,
        "admin"            => false
      },
      "id"                 =>  repo.id,
      "name"               =>  "minimal",
      "slug"               =>  "svenfuchs/minimal",
      "description"        => nil,
      "github_language"    => nil,
      "active"             => true,
      "private"            => true,
      "owner"              => {
        "id"               => repo.owner_id,
        "login"            => "svenfuchs",
        "@type"            => "user",
        "@href"            => "/v3/user/#{repo.owner_id}"},
      "default_branch"     => {
        "@type"            => "branch",
        "@href"            => "/v3/repo/#{repo.id}/branch/master",
        "@representation"  => "minimal",
        "name"             => "master"},
      "starred"            => false,
    }}
  end

  describe "private repository, private API, authenticated as user without access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: User.find(2), app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                          }}
    before        { repo.update_attribute(:private, true)                               }
    before        { get("/v3/repo/#{repo.id}", {}, headers)                             }
    before        { repo.update_attribute(:private, false)                              }
    example       { expect(last_response).to be_not_found                               }
    example       { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "private repository without cron feature, authenticated as internal application with full access" do
    let(:app_name)   { 'travis-example'                                                           }
    let(:app_secret) { '12345678'                                                                 }
    let(:sign_opts)  { "a=#{app_name}"                                                            }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts)                   }
    let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}"            }}
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}


    before { repo.update_attribute(:private, true)   }
    before { get("/v3/repo/#{repo.id}", {}, headers) }
    before { repo.update_attribute(:private, false)  }


    example { expect(last_response).to be_ok   }
    example { expect(parsed_body).to be == {
      "@type"              => "repository",
      "@href"              => "/v3/repo/#{repo.id}",
      "@representation"    => "standard",
      "@permissions"       => {
        "read"             => true,
        "activate"         => true,
        "deactivate"       => true,
        "star"             => true,
        "unstar"           => true,
        "create_request"   => true,
        "create_cron"      => true,
        "change_env_vars"  => true,
        "change_key"       => true,
        "admin"            => false
      },
      "id"                 =>  repo.id,
      "name"               =>  "minimal",
      "slug"               =>  "svenfuchs/minimal",
      "description"        => nil,
      "github_language"    => nil,
      "active"             => true,
      "private"            => true,
      "owner"              => {
        "id"               => repo.owner_id,
        "login"            => "svenfuchs",
        "@type"            => "user",
        "@href"            => "/v3/user/#{repo.owner_id}"},
      "default_branch"     => {
        "@type"            => "branch",
        "@href"            => "/v3/repo/#{repo.id}/branch/master",
        "@representation"  => "minimal",
        "name"             => "master"},
      "starred"            => false,
    }}
  end

  describe "private repository, authenticated as internal application with full access, but scoped to a different org" do
    let(:app_name)   { 'travis-example'                                                           }
    let(:app_secret) { '12345678'                                                                 }
    let(:sign_opts)  { "a=#{app_name}:s=travis-pro"                                               }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts)                   }
    let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}"            }}
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}

    before { repo.update_attribute(:private, true)   }
    before { get("/v3/repo/#{repo.id}", {}, headers) }
    before { repo.update_attribute(:private, false)  }

    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "private repository without cron feature, authenticated as user with admin access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}

    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, push: true, admin: true) }
    before { repo.update_attribute(:private, true)   }
    before { get("/v3/repo/#{repo.id}", {}, headers) }

    example { expect(last_response).to be_ok   }
    example { expect(parsed_body).to be == {
      "@type"              => "repository",
      "@href"              => "/v3/repo/#{repo.id}",
      "@representation"    => "standard",
      "@permissions"       => {
        "read"             => true,
        "activate"         => true,
        "deactivate"       => true,
        "star"             => true,
        "unstar"           => true,
        "create_request"   => true,
        "create_cron"      => true,
        "change_env_vars"  => true,
        "change_key"       => true,
        "admin"            => true
      },
      "id"                 =>  repo.id,
      "name"               =>  "minimal",
      "slug"               =>  "svenfuchs/minimal",
      "description"        => nil,
      "github_language"    => nil,
      "active"             => true,
      "private"            => true,
      "owner"              => {
        "id"               => repo.owner_id,
        "login"            => "svenfuchs",
        "@type"            => "user",
        "@href"            => "/v3/user/#{repo.owner_id}"},
      "default_branch"     => {
        "@type"            => "branch",
        "@href"            => "/v3/repo/#{repo.id}/branch/master",
        "@representation"  => "minimal",
        "name"             => "master"},
      "starred"            => false,
    }}
  end

  describe "including full owner" do
    before  { get("/v3/repo/#{repo.id}?include=repository.owner") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body['owner']).to include("github_id", "is_syncing", "synced_at",
      "@type" => "user",
      "id"    => repo.owner_id,
      "login" => "svenfuchs",
    )}
  end

  describe "including full owner" do
    before  { get("/v3/repo/#{repo.id}?include=repository.owner") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body['owner']).to include("github_id", "is_syncing", "synced_at")}
  end

  describe "including non-existing field" do
    before  { get("/v3/repo/#{repo.id}?include=repository.owner,repository.last_build_number") }
    example { expect(last_response.status).to be == 400 }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "no field \"repository.last_build_number\" to include"
    }}
  end

  describe "wrong include format" do
    before  { get("/v3/repo/#{repo.id}?include=repository.last_build.branch") }
    example { expect(last_response.status).to be == 400 }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "illegal format for include parameter"
    }}
  end
end
