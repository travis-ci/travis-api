
describe Travis::API::V3::Services::Build::Restart, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:payload) { { 'id'=> "#{build.id}", 'user_id' => 1 } }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }
  before do
    build.update(state: :passed)
    Travis.config.billing.url = 'http://localhost:9292/'
    Travis.config.billing.auth_key = 'secret'

    stub_request(:post, /http:\/\/localhost:9292\/(users|organizations)\/(.+)\/authorize_build/).to_return(
      body: MultiJson.dump(allowed: true, rejection_code: nil)
    )

    allow(Travis::Features).to receive(:owner_active?).and_return(true)
    allow(Travis::Features).to receive(:owner_active?).with(:enqueue_to_hub, repo.owner).and_return(false)
    allow(Travis::Features).to receive(:owner_active?).with(:read_only_disabled, repo.owner).and_return(true)
    @original_sidekiq = Sidekiq::Client
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = []
  end

  after do
    Travis.config.billing.url = nil
    Travis.config.billing.auth_key = nil
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = @original_sidekiq
  end

  describe "not authenticated" do
    before  { post("/v3/build/#{build.id}/restart")      }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

  describe "missing build, authenticated" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { post("/v3/build/9999999999/restart", {}, headers)                 }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "build not found (or insufficient access)",
      "resource_type" => "build"
    }}
  end

  context do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before  { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }

    describe "repo migrating on .com" do
      before  { Travis.config.host = "travis-ci.com" }
      before  { repo.update(migration_status: "migrating") }
      before  { post("/v3/build/#{build.id}/restart", {}, headers) }

      example { expect(last_response.status).to be == 202 }
    end

    describe "repo migrating" do
      before  { repo.update(migration_status: "migrating") }
      before  { post("/v3/build/#{build.id}/restart", {}, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before  { repo.update(migration_status: "migrated") }
      before  { post("/v3/build/#{build.id}/restart", {}, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end

  describe "existing repository, repo owner ro_mode" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
      allow(Travis::Features).to receive(:owner_active?).with(:read_only_disabled, repo.owner).and_return(false)
      post("/v3/build/#{build.id}/restart", {}, headers)
    end

    example { expect(last_response.status).to be == 404 }
  end

  describe "existing repository, pull access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
      post("/v3/build/#{build.id}/restart", {}, headers)
    end

    example { expect(last_response.status).to be == 202 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "build",
      "event_type",
      "push")
    }
  end

  describe "existing repo, repo owner is flagged abusive" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
      Travis.redis.sadd("abuse:offenders", "#{build.owner.class.name.split("::").last}:#{build.owner_id}")
      post("/v3/build/#{build.id}/restart", {}, headers)
    end

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "error",
      "error_message" => "Abuse detected. Restart disabled. If you think you have received this message in error, please contact support: support@travis-ci.com"
    }}
  end

  describe "private repository, no access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { repo.update_attribute(:private, true)                             }
    before        { post("/v3/build/#{build.id}/restart", {}, headers)                 }
    after         { repo.update_attribute(:private, false)                            }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "build not found (or insufficient access)",
      "resource_type" => "build"
    }}
  end

  describe "existing repository, pull access, build already running" do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)                          }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                                                 }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }

    describe "started state" do
      before        { build.update_attribute(:state, "started")                                                   }
      before        { post("/v3/build/#{build.id}/restart", params, headers)                                      }

      example { expect(last_response.status).to be == 409 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "build_already_running",
        "error_message" => "build already running, cannot restart"
      }}
    end

    describe "queued state" do
      before        { build.update_attribute(:state, "queued")                                                   }
      before        { post("/v3/build/#{build.id}/restart", params, headers)                                     }

      example { expect(last_response.status).to be == 409 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "build_already_running",
        "error_message" => "build already running, cannot restart"
      }}
    end

    describe "received state" do
      before        { build.update_attribute(:state, "received")                                                  }
      before        { post("/v3/build/#{build.id}/restart", params, headers)                                      }

      example { expect(last_response.status).to be == 409 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "build_already_running",
        "error_message" => "build already running, cannot restart"
      }}
    end
  end

  describe "existing repository, pull access, build not already running, enqueues message for Hub" do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)                          }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                                                 }}
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
      allow(Travis::Features).to receive(:owner_active?).with(:enqueue_to_hub, repo.owner).and_return(true)
    end

    shared_examples 'clears debug_options for all jobs' do
      before  { build.jobs.each { |j| j.update_attribute(:debug_options, { 'foo' => 'bar' }) } }
      example { build.jobs.each { |j| expect(j.reload.debug_options).to be_nil } }
    end

    describe "errored state" do
      include_examples 'clears debug_options for all jobs'

      before do
        build.update_attribute(:state, "errored")
        post("/v3/build/#{build.id}/restart", params, headers)
      end

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "pending",
        "build",
        "@href",
        "@representation",
        "minimal",
        "restart",
        "id",
        "state_change")
      }

      example { expect(payload).to be == {
        "id"     => "#{build.id}",
        "user_id"=> repo.owner_id}
      }

      example { expect(Sidekiq::Client.last['queue']).to be == 'hub'                          }
      example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Hub::Sidekiq::Worker' }
    end

    describe "passed state" do
      include_examples 'clears debug_options for all jobs'

      before        { build.update_attribute(:state, "passed")                                                  }
      before        { post("/v3/build/#{build.id}/restart", params, headers)                                    }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "pending",
        "build",
        "@href",
        "@representation",
        "minimal",
        "restart",
        "id",
        "state_change")
      }

      example { expect(payload).to be == {
        "id"     => "#{build.id}",
        "user_id"=> repo.owner_id}
      }

      example { expect(Sidekiq::Client.last['queue']).to be == 'hub'                          }
      example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Hub::Sidekiq::Worker' }
    end

    describe "failed state" do
      include_examples 'clears debug_options for all jobs'

      before        { build.update_attribute(:state, "failed")                                                  }
      before        { post("/v3/build/#{build.id}/restart", params, headers)                                    }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "pending",
        "build",
        "@href",
        "@representation",
        "minimal",
        "restart",
        "id",
        "state_change")
      }

      example { expect(payload).to be == {
        "id"     => "#{build.id}",
        "user_id"=> repo.owner_id}
      }

      example { expect(Sidekiq::Client.last['queue']).to be == 'hub'                          }
      example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Hub::Sidekiq::Worker' }
    end

    describe "canceled state" do
      include_examples 'clears debug_options for all jobs'

      before        { build.update_attribute(:state, "canceled")                                                  }
      before        { post("/v3/build/#{build.id}/restart", params, headers)                                      }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "pending",
        "build",
        "@href",
        "@representation",
        "minimal",
        "restart",
        "id",
        "state_change")
      }

      example { expect(payload).to be == {
        "id"     => "#{build.id}",
        "user_id"=> repo.owner_id}
      }

      example { expect(Sidekiq::Client.last['queue']).to be == 'hub'                          }
      example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Hub::Sidekiq::Worker' }
    end

    describe "setting id has no effect" do
      before        { build.update_attribute(:state, "canceled")               }
      before        { post("/v3/build/#{build.id}/restart", params, headers)   }
      let(:params) {{ id: 42 }}

      example { expect(payload).to be == {
        "id"     => "#{build.id}",
        "user_id"=> repo.owner_id}
      }
    end
  end

  #  TODO decided to discuss further with rkh as this use case doesn't really exist at the moment
  #  and 'fixing' the query requires modifying workers that v2 uses, thereby running the risk of breaking v2,
  #  and also because in 6 months or so travis-hub will be able to cancel builds without using travis-core at all.
  #
  # describe "existing repository, application with full access" do
  #   let(:app_name)   { 'travis-example'                                                           }
  #   let(:app_secret) { '12345678'                                                                 }
  #   let(:sign_opts)  { "a=#{app_name}"                                                            }
  #   let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts)                   }
  #   let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}"            }}
  #   before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}
  #   before { post("/v3/build/#{build.id}/restart", params, headers)                                }
  #
  #   describe 'without setting user' do
  #     let(:params) {{}}
  #     example { expect(last_response.status).to be == 400 }
  #     example { expect(JSON.load(body)).to      be ==     {
  #       "@type"         => "error",
  #       "error_type"    => "wrong_params",
  #       "error_message" => "missing user"
  #     }}
  #   end
  #
  #   describe 'setting user' do
  #     let(:params) {{ user: { id: repo.owner.id } }}
  #     example { expect(last_response.status).to be == 202 }
  #     example { expect(payload).to be == {
  #       # repository: { id: repo.id, owner_name: 'svenfuchs', name: 'minimal' },
  #       # user:       { id: repo.owner.id },
  #       # message:    nil,
  #       # branch:     'master',
  #       # config:     {}
  #     }}
  #   end
  # end
end
