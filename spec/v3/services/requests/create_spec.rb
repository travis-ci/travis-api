describe Travis::API::V3::Services::Requests::Create, set_app: true do
  let(:repo)    { Factory(:repository_without_last_build, owner_name: 'svenfuchs', name: 'minimal') }
  let(:request) { Travis::API::V3::Models::Request.last }
  let(:sidekiq_payload) { JSON.load(Sidekiq::Client.last['args'].last[:payload]).deep_symbolize_keys }
  let(:sidekiq_params) { Sidekiq::Client.last['args'].last.deep_symbolize_keys }
  before {
    ActiveRecord::Base.connection.execute("truncate requests cascade")
    ActiveRecord::Base.connection.execute("truncate repositories cascade")
  }

  before do
    Travis::Features.stubs(:owner_active?).returns(true)
    @original_sidekiq = Sidekiq::Client
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = []
  end

  after do
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = @original_sidekiq
  end

  describe "not authenticated" do
    before  { post("/v3/repo/#{repo.id}/requests")      }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

  describe "missing repository, authenticated" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { post("/v3/repo/9999999999/requests", {}, headers)                 }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "existing repository, no push access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { post("/v3/repo/#{repo.id}/requests", {}, headers)                 }

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "error_type",
      "error_message",
      "operation requires create_request access to repository",
      "resource_type",
      "repository",
      "permission",
      "create_request")
    }
  end

  describe "private repository, no access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { repo.update_attribute(:private, true)                             }
    before        { post("/v3/repo/#{repo.id}/requests", {}, headers)                 }
    after         { repo.update_attribute(:private, false)                            }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "existing repository, push access" do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)                          }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                                                 }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before        { post("/v3/repo/#{repo.id}/requests", params, headers)                                      }

    example { expect(last_response.status).to be == 202 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "pending",
      "remaining_requests",
      "repository",
      "@href",
      "@representation",
      "minimal",
      "request",
      "user",
      "resource_type",
      "request")
    }

    example { expect(sidekiq_payload).to be == {
      repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
      user:       { id: repo.owner.id },
      id:         request.id,
      message:    nil,
      branch:     'master',
      config:     {}
    }}

    example { expect(Sidekiq::Client.last['queue']).to be == 'build_requests'                }
    example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Gatekeeper::Worker' }

    describe "setting id has no effect" do
      let(:params) {{ id: 42 }}
      example { expect(sidekiq_payload).to be == {
        repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
        user:       { id: repo.owner.id },
        id:         request.id,
        message:    nil,
        branch:     'master',
        config:     {}
      }}
    end

    describe "setting repository has no effect" do
      let(:params) {{ repository: { id: 42 } }}
      example { expect(sidekiq_payload).to be == {
        repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
        user:       { id: repo.owner.id },
        id:         request.id,
        message:    nil,
        branch:     'master',
        config:     {}
      }}
    end

    describe "setting user has no effect" do
      let(:params) {{ user: { id: 42 } }}
      example { expect(sidekiq_payload).to be == {
        repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
        user:       { id: repo.owner.id },
        id:         request.id,
        message:    nil,
        branch:     'master',
        config:     {}
      }}
    end

    describe "overriding config" do
      let(:params) {{ config: { script: 'true' } }}
      example { expect(sidekiq_payload).to be == {
        repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
        user:       { id: repo.owner.id },
        id:         request.id,
        message:    nil,
        branch:     'master',
        config:     { script: 'true' }
      }}
    end

    describe "overriding message" do
      let(:params) {{ message: 'example' }}
      example { expect(sidekiq_payload).to be == {
        repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
        user:       { id: repo.owner.id },
        id:         request.id,
        message:    'example',
        branch:     'master',
        config:     {}
      }}
    end

    describe "overriding branch" do
      let(:params) {{ branch: 'example' }}
      example { expect(sidekiq_payload).to be == {
        repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
        user:       { id: repo.owner.id },
        id:         request.id,
        message:    nil,
        branch:     'example',
        config:     {}
      }}
    end

    describe "overriding branch (in request)" do
      let(:params) {{ request: { branch: 'example' } }}
      example { expect(sidekiq_payload).to be == {
        repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
        user:       { id: repo.owner.id },
        id:         request.id,
        message:    nil,
        branch:     'example',
        config:     {}
      }}
    end

    describe "overriding branch (with request prefix)" do
      let(:params) {{ "request.branch" => 'example' }}
      example { expect(sidekiq_payload).to be == {
        repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
        user:       { id: repo.owner.id },
        id:         request.id,
        message:    nil,
        branch:     'example',
        config:     {}
      }}
    end

    describe "overriding branch (with request type)" do
      let(:params) {{ "@type" => "request", "branch" => 'example' }}
      example { expect(sidekiq_payload).to be == {
        repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
        user:       { id: repo.owner.id },
        id:         request.id,
        message:    nil,
        branch:     'example',
        config:     {}
      }}
    end

    describe "overriding branch (with wrong type)" do
      let(:params) {{ "@type" => "repository", "branch" => 'example' }}
      example { expect(sidekiq_payload).to be == {
        repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
        user:       { id: repo.owner.id },
        id:         request.id,
        message:    nil,
        branch:     'master',
        config:     {}
      }}
    end

    describe "when the repository is inactive" do
      before { repo.update_attributes!(active: false) }
      before { post("/v3/repo/#{repo.id}/requests", params, headers) }

      example { expect(last_response.status).to be == 406 }
      example { expect(body).to include(
        "@type",
        "error",
        "error_type",
        "error_type",
        "repository_inactive",
        "error_message",
        "cannot create requests on an inactive repository")
      }
    end

    describe "when request limit is reached" do
      before { 10.times { repo.requests.create(event_type: 'api') } }
      before { post("/v3/repo/#{repo.id}/requests", params, headers) }

      example { expect(last_response.status).to be == 429 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "error",
        "error_type",
        "request_limit_reached",
        "error_message",
        "request limit reached for resource",
        "repository",
        "representation",
        "minimal",
        "slug",
        "svenfuchs/minimal",
        "max_requests",
        "per_seconds")
      }
    end

    describe "overrides default request limit if included in repository.settings" do
      before { repo.update_attribute(:settings, { api_builds_rate_limit: 12 }.to_json) }

      before { 10.times { repo.requests.create(event_type: 'api') } }
      before { post("/v3/repo/#{repo.id}/requests", {}, headers) }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to  include(
        "@type",
        "repository",
        "remaining_requests",
        "1",
        "request",
        "representation",
        "minimal",
        "slug",
        "svenfuchs/minimal")
      }
    end

    describe "passing the token in params" do
      let(:params) {{ request: { token: 'foo-bar' }}}
      example { expect(sidekiq_params[:credentials]).to be == {
        token: 'foo-bar'
      }}
    end
  end


  describe "existing repository, application with full access" do
    let(:app_name)   { 'travis-example'                                                           }
    let(:app_secret) { '12345678'                                                                 }
    let(:sign_opts)  { "a=#{app_name}"                                                            }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts)                   }
    let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}"            }}
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}
    before { post("/v3/repo/#{repo.id}/requests", params, headers)                                }

    describe 'without setting user' do
      let(:params) {{}}
      example { expect(last_response.status).to be == 400 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "wrong_params",
        "error_message" => "missing user"
      }}
    end

    describe 'setting user' do
      let(:params) {{ user: { id: repo.owner.id } }}
      example { expect(last_response.status).to be == 202 }
      example { expect(sidekiq_payload).to be == {
        repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
        user:       { id: repo.owner.id },
        id:         request.id,
        message:    nil,
        branch:     'master',
        config:     {}
      }}
    end

    describe 'setting branch' do
      let(:params) {{ user: { id: repo.owner.id }, branch: 'example' }}
      example { expect(last_response.status).to be == 202 }
      example { expect(sidekiq_payload).to be == {
        repository: { id: repo.github_id, owner_name: 'svenfuchs', name: 'minimal' },
        user:       { id: repo.owner.id },
        id:         request.id,
        message:    nil,
        branch:     'example',
        config:     {}
      }}
    end
  end

  context do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }

    describe "repo migrating" do
      before { repo.update_attributes(migration_status: "migrating") }
      before { post("/v3/repo/#{repo.id}/requests", {}, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before { repo.update_attributes(migration_status: "migrated") }
      before { post("/v3/repo/#{repo.id}/deactivate", {}, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
