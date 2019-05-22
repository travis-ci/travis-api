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

  describe "missing repo, authenticated" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { post("/v3/repo/9999999999/activate", {}, headers)                 }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end
      before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, pull: true, push: true) }
      before { Travis::API::V3::GitHub.any_instance.stubs(:upload_key) }
      before { stub_request(:any, %r(https://api.github.com/repositories/#{repo.github_id}/hooks(/\d+)?)) }

  describe "existing repository, no push access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { post("/v3/repo/#{repo.id}/activate", {}, headers)                 }
      before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, pull: true, push: true) }
      before { Travis::API::V3::GitHub.any_instance.stubs(:upload_key) }
      before { stub_request(:any, %r(https://api.github.com/repositories/#{repo.github_id}/hooks(/\d+)?)) }

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
      "activate")
    }
  end

  describe "private repository, no access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
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

  describe "existing repository, push access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    let(:webhook_payload) { JSON.dump(name: 'web', events: Travis::API::V3::GitHub::EVENTS, active: true, config: { url: Travis.config.service_hook_url || '', insecure_ssl: false }) }
    let(:service_hook_payload) { JSON.dump(events: Travis::API::V3::GitHub::EVENTS, active: false) }

    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, pull: true, push: true) }
    before        { Travis::API::V3::GitHub.any_instance.stubs(:upload_key) }
    before        { stub_request(:any, %r(https://api.github.com/repos/#{repo.slug}/hooks(/\d+)?)) }

    around do |ex|
      Travis.config.service_hook_url = 'https://url.of.listener.something'
      ex.run
      Travis.config.service_hook_url = nil
    end

    context 'queues sidekiq job' do
      before do
        stub_request(:get, "https://api.github.com/repos/#{repo.slug}/hooks?per_page=100").to_return(status: 200, body: '[]')
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
        stub_request(:get, "https://api.github.com/repos/#{repo.slug}/hooks?per_page=100").to_return(
          status: 200, body: JSON.dump(
            [
              { name: 'travis', url: "https://api.github.com/repos/#{repo.slug}/hooks/123" },
              { name: 'web', url: "https://api.github.com/repos/#{repo.slug}/hooks/456", config: { url: Travis.config.service_hook_url, insecure_ssl: false } }
            ]
          )
        )
        post("/v3/repo/#{repo.id}/activate", {}, headers)
      end

      example 'deactivates service hook' do
        expect(WebMock).to have_requested(:patch, "https://api.github.com/repos/#{repo.slug}/hooks/123").with(body: service_hook_payload).once
      end

      example 'updates webhook' do
        expect(WebMock).to have_requested(:patch, "https://api.github.com/repos/#{repo.slug}/hooks/456").with(body: webhook_payload).once
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
        stub_request(:get, "https://api.github.com/repos/#{repo.slug}/hooks?per_page=100").to_return(
          status: 200, body: JSON.dump(
            [
              { name: 'web', url: "https://api.github.com/repos/#{repo.slug}/hooks/456", config: { url: Travis.config.service_hook_url, insecure_ssl: false } }
            ]
          )
        )
        post("/v3/repo/#{repo.id}/activate", {}, headers)
      end

      example 'updates webhook' do
        expect(WebMock).to have_requested(:patch, "https://api.github.com/repos/#{repo.slug}/hooks/456").with(body: webhook_payload).once
      end

      example 'is success' do
        expect(last_response.status).to eq 200
        expect(JSON.load(body)).to include(
          '@type' => 'repository',
          'active' => true
        )
      end

      context 'when ssl verification has been disabled' do
        let(:webhook_payload) { JSON.dump(name: 'web', events: Travis::API::V3::GitHub::EVENTS, active: true, config: { url: Travis.config.service_hook_url || '', insecure_ssl: true }) }

        around do |ex|
          Travis.config.ssl = { verify: false }
          ex.run
          Travis.config.ssl = {}
        end

        example 'updates webhook with ssl disabled' do
          expect(WebMock).to have_requested(:patch, "https://api.github.com/repos/#{repo.slug}/hooks/456").with(body: webhook_payload).once
        end

        example 'is success' do
          expect(last_response.status).to eq 200
          expect(JSON.load(body)).to include(
            '@type' => 'repository',
            'active' => true
          )
        end
      end

      context 'when the repo ssh key does not exist' do
        before do
          repo.key.destroy
          post("/v3/repo/#{repo.id}/activate", {}, headers)
        end

        example { expect(last_response.status).to eq 409 }

        example do
          expect(JSON.load(body)).to eq(
            '@type' => 'error',
            'error_type' => 'repo_ssh_key_missing',
            'error_message' => 'request cannot be completed because the repo ssh key is still pending to be created. please retry in a bit, or try syncing the repository if this condition does not resolve'
          )
        end
      end

      context 'when the repo ssh key does not exist' do
        before do
          repo.key.destroy
          post("/v3/repo/#{repo.id}/activate", {}, headers)
        end

        example { expect(last_response.status).to eq 409 }

        example do
          expect(JSON.load(body)).to eq(
            '@type' => 'error',
            'error_type' => 'repo_ssh_key_missing',
            'error_message' => 'request cannot be completed because the repo ssh key is still pending to be created. please retry in a bit, or try syncing the repository if this condition does not resolve'
          )
        end
      end
    end

    context 'when webhook does not exist' do
      before do
        stub_request(:get, "https://api.github.com/repos/#{repo.slug}/hooks?per_page=100").to_return(status: 200, body: '[]')
        post("/v3/repo/#{repo.id}/activate", {}, headers)
      end

      example 'creates webhook' do
        expect(WebMock).to have_requested(:post, "https://api.github.com/repos/#{repo.slug}/hooks").once
      end

      example 'is success' do
        expect(last_response.status).to eq 200
        expect(JSON.load(body)).to include(
          '@type' => 'repository',
          'active' => true
        )
      end

      context 'when ssl verification has been disabled' do
        let(:webhook_payload) { JSON.dump(name: 'web', events: Travis::API::V3::GitHub::EVENTS, active: true, config: { url: Travis.config.service_hook_url || '', insecure_ssl: true}) }

        around do |ex|
          Travis.config.ssl = { verify: false }
          ex.run
          Travis.config.ssl = {}
        end

        example 'requests webhooks without ssl verification' do
          expect(WebMock).to have_requested(:post, "https://api.github.com/repos/#{repo.slug}/hooks").with(body: webhook_payload).once
        end
      end
    end
  end
end
