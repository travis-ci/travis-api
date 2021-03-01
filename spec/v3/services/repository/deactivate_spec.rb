describe Travis::API::V3::Services::Repository::Deactivate, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  before do
    Travis.config.vcs.url = 'http://vcsfake.travis-ci.com'
    Travis.config.vcs.token = 'vcs-token'
    repo.update_attributes!(active: true)
  end
  describe "not authenticated" do
    before  { post("/v3/repo/#{repo.id}/deactivate")      }
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
    before        { post("/v3/repo/9999999999/deactivate", {}, headers)                 }
    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end
  shared_examples 'repository deactivation' do
    describe 'existing repository, wrong access' do
      before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
      before { post("/v3/repo/#{repo.id}/deactivate", {}, headers) }
      example 'is success' do
        expect(last_response.status).to eq 403
        expect(JSON.load(body)).to include(
          '@type' => 'error',
          'error_type' => 'admin_access_required'
        )
      end
    end
    describe "existing repository, admin and push access" do
      let!(:request) do
        stub_request(:delete, "http://vcsfake.travis-ci.com/repos/#{repo.id}/hook?user_id=#{repo.owner_id}")
          .to_return(
            status: 200,
            body: nil,
          )
      end
      before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, push: true) }
      around do |ex|
        Travis.config.service_hook_url = 'https://url.of.listener.something'
        ex.run
        Travis.config.service_hook_url = nil
      end
      example 'creates webhook' do
        post("/v3/repo/#{repo.id}/deactivate", {}, headers)
        expect(request).to have_been_made
        expect(last_response.status).to eq 200
        expect(JSON.load(body)).to include(
          '@type' => 'repository',
          'active' => false
        )
      end
    end
  end
  context 'user auth' do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    it_behaves_like 'repository deactivation'
    describe "existing repository, no push access" do
      before        { post("/v3/repo/#{repo.id}/deactivate", {}, headers)                 }
      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "error_type",
        "insufficient_access",
        "error_message",
        "operation requires deactivate access to repository",
        "resource_type",
        "repository",
        "permission",
        "deactivate")
      }
    end
    describe "private repository, no access" do
      before        { repo.update_attribute(:private, true)                             }
      before        { post("/v3/repo/#{repo.id}/deactivate", {}, headers)                 }
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
  context 'internal auth' do
    let(:internal_token) { 'FOO' }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "internal admin:#{internal_token}" } }
    around do |ex|
      apps = Travis.config.applications
      Travis.config.applications = { 'admin' => { token: internal_token, full_access: true }}
      ex.run
      Travis.config.applications = apps
    end
    it_behaves_like 'repository deactivation'
  end
  describe "existing repository, push access"
  # as this requires a call to github, and stubbing this request has proven difficult,
  # this test has been omitted for now
  context do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, push: true, pull: true) }
    describe "repo migrating" do
      before { repo.update_attributes(migration_status: "migrating") }
      before { post("/v3/repo/#{repo.id}/deactivate", {}, headers) }
      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
    describe "repo migrated" do
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
