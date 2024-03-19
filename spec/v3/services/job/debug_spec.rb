describe Travis::API::V3::Services::Job::Debug, set_app: true do
  let(:repo) { FactoryBot.create(:repository, owner_name: 'svenfuchs', name: 'minimal') }
  let(:owner_type)  { repo.owner_type.constantize }
  let(:owner)       { owner_type.find(repo.owner_id)}
  let(:build)       { repo.builds.last }
  let(:jobs)        { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:job)         { jobs.last }

  before { ActiveRecord::Base.connection.execute("truncate requests cascade") }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  before do
    Travis.config.billing.url = 'http://localhost:9292/'
    Travis.config.billing.auth_key = 'secret'
    allow(Travis::Features).to receive(:owner_active?).and_return(true)
    @original_sidekiq = Sidekiq::Client
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = []
    Travis::Features.activate_repository(:debug_tools, job.repository)

    stub_request(:post, /http:\/\/localhost:9292\/(users|organizations)\/(.+)\/authorize_build/).to_return(
      body: MultiJson.dump(allowed: true, rejection_code: nil)
    )
  end

  after do
    Travis.config.billing.url = nil
    Travis.config.billing.auth_key = nil
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = @original_sidekiq
  end

  shared_examples_for "returns 202 but no error" do
    example { expect(last_response.status).to be == 202 }
    example { expect(job.reload.debug_options).to include(
      stage: "before_install",
      created_by: owner.login,
      quiet: false
    ) }
  end

  describe "#run" do
    context "when unauthenticated" do
      before  { post("/v3/job/#{job.id}/debug")      }
      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "login_required",
        "error_message" => "login required"
      }}
    end

    context "when authenticated" do
      let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
      let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}

      context "without sufficient authorization" do
        let(:authorization) { { 'permissions' => ['repository_settings_read'] } }
        before { post("/v3/job/#{job.id}/debug", {}, headers) }

        example { expect(last_response.status).to be == 403 }
        example { expect(JSON.load(body)).to include(
          "@type"         => "error",
          "error_type"    => "insufficient_access",
          "error_message" => "operation requires debug access to job",
          "resource_type" => "job",
        )}
      end

      context "with sufficient authorization" do
        let(:params) {{}}

        before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true, pull: true) }

        context "for a public repo" do
          context "with debug_tools enabled" do
            before { post("/v3/job/#{job.id}/debug", {}, headers) }

            include_examples "returns 202 but no error"
          end

          context "with debug_tools disabled" do
            before do
              Travis::Features.deactivate_repository(:debug_tools, job.repository)
              post("/v3/job/#{job.id}/debug", {}, headers)
            end

            example { expect(last_response.status).to be == 403 }
            example { expect(JSON.load(body)).to include(
              "@type"         => "error",
              "error_message" => "access denied",
              "error_type" => "wrong_credentials"
            )}
          end
        end

        context "for a private repo" do
          before do
            job.repository.update!(private: true)
            post("/v3/job/#{job.id}/debug", {}, headers)
          end

          include_examples "returns 202 but no error"
        end
      end
    end
  end

  context do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}"} }
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }

    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before { post("/v3/job/#{job.id}/debug", {}, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before { repo.update(migration_status: "migrated") }
      before { post("/v3/job/#{job.id}/debug", {}, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
