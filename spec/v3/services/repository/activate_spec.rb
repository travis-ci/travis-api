describe Travis::API::V3::Services::Repository::Activate, set_app: true do
  let(:sidekiq_job) { Sidekiq::Client.last.deep_symbolize_keys }
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  before do
    repo.update_attributes!(active: false)
    @original_sidekiq = Sidekiq::Client
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = []
  end

  after do
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = @original_sidekiq
  end

  describe "not authenticated" do
    before  { post("/v3/repo/#{repo.id}/activate")      }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

  shared_examples 'repository activation' do
    describe "missing repo, authenticated" do
      before        { post("/v3/repo/9999999999/activate", {}, headers)                 }

      example { expect(last_response.status).to be == 404 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "not_found",
        "error_message" => "repository not found (or insufficient access)",
        "resource_type" => "repository"
      }}
    end

    describe "existing repository, push access" do
      let(:webhook_payload) { JSON.dump(name: 'web', events: Travis::API::V3::GitHub::EVENTS, active: true, config: { url: Travis.config.service_hook_url || '' }) }
      let(:service_hook_payload) { JSON.dump(events: Travis::API::V3::GitHub::EVENTS, active: false) }

      before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, pull: true, push: true) }
      before        { Travis::API::V3::GitHub.any_instance.stubs(:upload_key) }
      before        { stub_request(:any, %r(https://api.github.com/repositories/#{repo.github_id}/hooks(/\d+)?)) }

      around do |ex|
        Travis.config.service_hook_url = 'https://url.of.listener.something'
        ex.run
        Travis.config.service_hook_url = nil
      end

      context 'queues sidekiq job' do
        before do
          stub_request(:get, "https://api.github.com/repositories/#{repo.github_id}/hooks?per_page=100").to_return(status: 200, body: '[]')
          post("/v3/repo/#{repo.id}/activate", {}, headers)
        end

        example do
          expect(sidekiq_job).to eq(
            queue: :sync,
            class: 'Travis::GithubSync::Worker',
            args:  [:sync_repo, repo_id: 1, user_id: 1]
          )
        end
      end

      context 'when both service hook and webhook exist' do
        before do
          stub_request(:get, "https://api.github.com/repositories/#{repo.github_id}/hooks?per_page=100").to_return(
            status: 200, body: JSON.dump(
              [
                { name: 'travis', url: "https://api.github.com/repositories/#{repo.github_id}/hooks/123" },
                { name: 'web', url: "https://api.github.com/repositories/#{repo.github_id}/hooks/456", config: { url: Travis.config.service_hook_url } }
              ]
            )
          )
          post("/v3/repo/#{repo.id}/activate", {}, headers)
        end

        example 'deactivates service hook' do
          expect(WebMock).to have_requested(:patch, "https://api.github.com/repositories/#{repo.github_id}/hooks/123").with(body: service_hook_payload).once
        end

        example 'updates webhook' do
          expect(WebMock).to have_requested(:patch, "https://api.github.com/repositories/#{repo.github_id}/hooks/456").with(body: webhook_payload).once
        end

        example 'is success' do
          expect(last_response.status).to eq 200
          expect(JSON.load(body)).to include(
            '@type' => 'repository',
            'active' => true
          )
        end
      end

      context 'when webhook exists' do
        before do
          stub_request(:get, "https://api.github.com/repositories/#{repo.github_id}/hooks?per_page=100").to_return(
            status: 200, body: JSON.dump(
              [
                { name: 'web', url: "https://api.github.com/repositories/#{repo.github_id}/hooks/456", config: { url: Travis.config.service_hook_url } }
              ]
            )
          )
          post("/v3/repo/#{repo.id}/activate", {}, headers)
        end

        example 'updates webhook' do
          expect(WebMock).to have_requested(:patch, "https://api.github.com/repositories/#{repo.github_id}/hooks/456").with(body: webhook_payload).once
        end

        example 'is success' do
          expect(last_response.status).to eq 200
          expect(JSON.load(body)).to include(
            '@type' => 'repository',
            'active' => true
          )
        end
      end

      context 'when webhook does not exist' do
        before do
          stub_request(:get, "https://api.github.com/repositories/#{repo.github_id}/hooks?per_page=100").to_return(status: 200, body: '[]')
          post("/v3/repo/#{repo.id}/activate", {}, headers)
        end

        example 'creates webhook' do
          expect(WebMock).to have_requested(:post, "https://api.github.com/repositories/#{repo.github_id}/hooks").once
        end

        example 'is success' do
          expect(last_response.status).to eq 200
          expect(JSON.load(body)).to include(
            '@type' => 'repository',
            'active' => true
          )
        end
      end
    end
  end

  context 'with user auth' do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    it_behaves_like 'repository activation'

    describe "existing repository, no push access" do
      before        { post("/v3/repo/#{repo.id}/activate", {}, headers)                 }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "error_type",
        "insufficient_access",
        "error_message",
        "operation requires activate access to repository",
        "resource_type",
        "repository",
        "permission",
        "activate"
      )}
    end

    describe "private repository, no access" do
      before        { repo.update_attribute(:private, true)                             }
      before        { post("/v3/repo/#{repo.id}/activate", {}, headers)                 }
      after         { repo.update_attribute(:private, false)                            }

      example { expect(last_response.status).to be == 404 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "not_found",
        "error_message" => "repository not found (or insufficient access)",
        "resource_type" => "repository"
      }}
    end

  end

  context 'with internal auth' do
    let(:internal_token) { 'FOO' }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "internal admin:#{internal_token}" } }

    around do |ex|
      apps = Travis.config.applications
      Travis.config.applications = { 'admin' => { token: internal_token, full_access: true }}
      ex.run
      Travis.config.applications = apps
    end

    it_behaves_like 'repository activation'
  end

  context do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, push: true, pull: true) }

    describe "repo migrating" do
      before { repo.update_attributes(migration_status: "migrating") }
      before { post("/v3/repo/#{repo.id}/activate", {}, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before { repo.update_attributes(migration_status: "migrated") }
      before { post("/v3/repo/#{repo.id}/activate", {}, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
