describe Travis::API::V3::Services::Build::Cancel, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:payload) { { 'id'=> "#{build.id}", 'user_id' => 1, 'source' => 'api' } }

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
    before  { post("/v3/build/#{build.id}/cancel")      }
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
    before        { post("/v3/build/9999999999/cancel", {}, headers)                 }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "build not found (or insufficient access)",
      "resource_type" => "build"
    }}
  end

  describe "existing repository, pull access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { post("/v3/build/#{build.id}/cancel", {}, headers)                 }

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "build",
      "event_type",
      "push")
    }
  end

  describe "existing repository, push access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before        { post("/v3/build/#{build.id}/cancel", {}, headers)                 }

    example { expect(last_response.status).to be == 202 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "build",
      "event_type",
      "push")
    }
  end

  describe "private repository, no access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { repo.update_attribute(:private, true)                             }
    before        { post("/v3/build/#{build.id}/cancel", {}, headers)                 }
    after         { repo.update_attribute(:private, false)                            }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "build not found (or insufficient access)",
      "resource_type" => "build"
    }}
  end

  describe "existing repository, push access, not cancelable" do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)                          }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                                                 }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }

    describe "passed state" do
      before        { build.update_attribute(:state, "passed")                                                   }
      before        { post("/v3/build/#{build.id}/cancel", params, headers)                                      }

      example { expect(last_response.status).to be == 409 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "build_not_cancelable",
        "error_message" => "build is not running, cannot cancel"
      }}
    end

    describe "errored state" do
      before        { build.update_attribute(:state, "errored")                                                   }
      before        { post("/v3/build/#{build.id}/cancel", params, headers)                                      }

      example { expect(last_response.status).to be == 409 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "build_not_cancelable",
        "error_message" => "build is not running, cannot cancel"
      }}
    end

    describe "failed state" do
      before        { build.update_attribute(:state, "failed")                                                   }
      before        { post("/v3/build/#{build.id}/cancel", params, headers)                                      }

      example { expect(last_response.status).to be == 409 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "build_not_cancelable",
        "error_message" => "build is not running, cannot cancel"
      }}
    end

    describe "canceled state" do
      before        { build.update_attribute(:state, "canceled")                                                   }
      before        { post("/v3/build/#{build.id}/cancel", params, headers)                                      }

      example { expect(last_response.status).to be == 409 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "build_not_cancelable",
        "error_message" => "build is not running, cannot cancel"
      }}
    end
  end

  describe "existing repository, push & pull access, cancelable, enqueues message for Hub" do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)                          }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                                                 }}
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true, pull: true)
      Travis::Features.stubs(:owner_active?).with(:enqueue_to_hub, repo.owner).returns(true)
    end

    describe "started state" do
      before        { build.update_attribute(:state, "started")                                                  }
      before        { post("/v3/build/#{build.id}/cancel", params, headers)                                      }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "build",
        "@href",
        "@representation",
        "minimal",
        "cancel",
        "id",
        "state_change")
      }

      example { expect(payload).to be == {
        "id"     => "#{build.id}",
        "user_id"=> repo.owner_id,
        "source" => "api"}
      }

      example { expect(Sidekiq::Client.last['queue']).to be == 'hub' }
      example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Hub::Sidekiq::Worker' }
    end

    describe "queued state" do
      before        { build.update_attribute(:state, "queued")                                                  }
      before        { post("/v3/build/#{build.id}/cancel", params, headers)                                      }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "build",
        "@href",
        "@representation",
        "minimal",
        "cancel",
        "id",
        "state_change")
      }

      example { expect(payload).to be == {
        "id"     => "#{build.id}",
        "user_id"=> repo.owner_id,
        "source" => "api"}
      }

      example { expect(Sidekiq::Client.last['queue']).to be == 'hub'                }
      example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Hub::Sidekiq::Worker' }
    end

    describe "received state" do
      before        { build.update_attribute(:state, "received")                                                  }
      before        { post("/v3/build/#{build.id}/cancel", params, headers)                                      }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "build",
        "@href",
        "@representation",
        "minimal",
        "cancel",
        "id",
        "state_change")
      }

      example { expect(payload).to be == {
        "id"     => "#{build.id}",
        "user_id"=> repo.owner_id,
        "source" => "api"}
      }

      example { expect(Sidekiq::Client.last['queue']).to be == 'hub'                }
      example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Hub::Sidekiq::Worker' }
    end

    describe "setting id has no effect" do
      let(:params) {{ id: 42 }}
      before  { post("/v3/build/#{build.id}/cancel", params, headers)                                      }
      example { expect(payload).to be == {
        "id"     => "#{build.id}",
        "user_id"=> repo.owner_id,
        "source" => "api"}
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
  #   before { post("/v3/build/#{build.id}/cancel", params, headers)                                }
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
