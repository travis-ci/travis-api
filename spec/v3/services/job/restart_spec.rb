describe Travis::API::V3::Services::Job::Restart, set_app: true do
  let(:user)        { Travis::API::V3::Models::User.find_by_login('svenfuchs') }
  let(:repo)        { Travis::API::V3::Models::Repository.where(owner_name: user.login, name: 'minimal').first }
  let(:build)       { repo.builds.first }
  let(:job)         { build.jobs.first }
  let(:payload)     { { 'id'=> "#{job.id}", 'user_id' => 1 } }

  before do
    Travis::Features.stubs(:owner_active?).returns(true)
    Travis::Features.stubs(:owner_active?).with(:enqueue_to_hub, repo.owner).returns(false)
    @original_sidekiq = Sidekiq::Client
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = []
  end

  after do
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = @original_sidekiq
  end

  describe "not authenticated" do
    before  { post("/v3/job/#{job.id}/restart")      }
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
    before        { post("/v3/job/9999999999/restart", {}, headers)                 }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "job not found (or insufficient access)",
      "resource_type" => "job"
    }}
  end

  describe "existing repository, no push or pull access" do
      let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
      let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
      before        { post("/v3/job/#{job.id}/cancel", {}, headers)                 }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "error_type",
        "error_message",
        "operation requires cancel access to job",
        "resource_type",
        "job",
        "insufficient_access",
        "permission",
        "cancel")
      }
    end

  describe "existing repo, repo owner is flagged abusive" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
      Travis.redis.sadd("abuse:offenders", "#{job.owner.class.name.split("::").last}:#{job.owner_id}")
      post("/v3/job/#{job.id}/restart", {}, headers)
    end

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "error",
      "error_message" => "Abuse detected. Restart disabled. If you think you have received this message in error, please contact support: support@travis-ci.com"
    }}
  end

  describe "existing repository, push access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
      post("/v3/job/#{job.id}/restart", {}, headers)
    end

    example { expect(last_response.status).to be == 202 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "pending",
      "job",
      "restart")
    }
  end

  describe "private repository, no access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1, pull: true) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { repo.update_attribute(:private, true)                             }
    before        { post("/v3/job/#{job.id}/restart", {}, headers)                 }
    after         { repo.update_attribute(:private, false)                            }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "job not found (or insufficient access)",
      "resource_type" => "job"
    }}
  end

  describe "existing repository, push access, job not already running, enqueues message for Hub" do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)                          }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                                                 }}
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, push: true)
      Travis::Features.stubs(:owner_active?).with(:enqueue_to_hub, repo.owner).returns(true)
    end

    shared_examples 'clears debug_options' do
      before  { job.update_attribute(:debug_options, { 'foo' => 'bar' }) }
      example { expect(job.reload.debug_options).to be_nil }
    end

    describe "canceled state" do
      include_examples 'clears debug_options'

      before        { job.update_attribute(:state, "canceled")                                                }
      before        { post("/v3/job/#{job.id}/restart", params, headers)                                      }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "pending",
        "job",
        "@href",
        "@representation",
        "minimal",
        "restart",
        "id",
        "state_change")
      }

      example { expect(payload).to be == {
        "id"     => "#{job.id}",
        "user_id"=> repo.owner_id}
      }

      example { expect(Sidekiq::Client.last['queue']).to be == 'hub'                }
      example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Hub::Sidekiq::Worker' }
    end

    describe "errored state" do
      include_examples 'clears debug_options'

      before        { job.update_attribute(:state, "errored")                                                }
      before        { post("/v3/job/#{job.id}/restart", params, headers)                                      }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "pending",
        "job",
        "@href",
        "@representation",
        "minimal",
        "restart",
        "id",
        "state_change")
      }

      example { expect(payload).to be == {
        "id"     => "#{job.id}",
        "user_id"=> repo.owner_id}
      }

      example { expect(Sidekiq::Client.last['queue']).to be == 'hub'                }
      example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Hub::Sidekiq::Worker' }
    end

    describe "failed state" do
      include_examples 'clears debug_options'

      before        { job.update_attribute(:state, "failed")                                                }
      before        { post("/v3/job/#{job.id}/restart", params, headers)                                      }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "pending",
        "job",
        "@href",
        "@representation",
        "minimal",
        "restart",
        "id",
        "state_change")
      }

      example { expect(payload).to be == {
        "id"     => "#{job.id}",
        "user_id"=> repo.owner_id}
      }

      example { expect(Sidekiq::Client.last['queue']).to be == 'hub'                }
      example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Hub::Sidekiq::Worker' }
    end

    describe "passed state" do
      include_examples 'clears debug_options'

      before        { job.update_attribute(:state, "passed")                                                }
      before        { post("/v3/job/#{job.id}/restart", params, headers)                                      }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "pending",
        "job",
        "@href",
        "@representation",
        "minimal",
        "restart",
        "id",
        "state_change")
      }

      example { expect(payload).to be == {
        "id"     => "#{job.id}",
        "user_id"=> repo.owner_id}
      }

      example { expect(Sidekiq::Client.last['queue']).to be == 'hub'                }
      example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Hub::Sidekiq::Worker' }
    end

    describe "setting id has no effect" do
      before do
        job.update_attribute(:state, "passed")
        post("/v3/job/#{job.id}/restart", params, headers)
      end
      let(:params) {{ id: 42 }}

      example { expect(payload).to be == {
        "id"     => "#{job.id}",
        "user_id"=> repo.owner_id}
      }
    end
  end

  describe "existing repository, push access, job already running" do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)                          }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                                                 }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, push: true) }

    describe "started state" do
      before        { job.update_attribute(:state, "started")                                                   }
      before        { post("/v3/job/#{job.id}/restart", params, headers)                                      }

      example { expect(last_response.status).to be == 409 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "job_already_running",
        "error_message" => "job already running, cannot restart"
      }}
    end

    describe "queued state" do
      before        { job.update_attribute(:state, "queued")                                                   }
      before        { post("/v3/job/#{job.id}/restart", params, headers)                                     }

      example { expect(last_response.status).to be == 409 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "job_already_running",
        "error_message" => "job already running, cannot restart"
      }}
    end

    describe "received state" do
      before        { job.update_attribute(:state, "received")                                                  }
      before        { post("/v3/job/#{job.id}/restart", params, headers)                                      }

      example { expect(last_response.status).to be == 409 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "job_already_running",
        "error_message" => "job already running, cannot restart"
      }}
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
  #   before { post("/v3/job/#{job.id}/restart", params, headers)                                }
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
