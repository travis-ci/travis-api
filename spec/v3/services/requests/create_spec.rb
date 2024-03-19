describe Travis::API::V3::Services::Requests::Create, set_app: true do
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:repo) { FactoryBot.create(:repository_without_last_build, owner_name: 'svenfuchs', name: 'minimal') }
  let(:request) { Travis::API::V3::Models::Request.last }
  let(:sidekiq_job) { Sidekiq::Queues['build_requests'].first }
  let(:sidekiq_payload) { JSON.parse(JSON.parse(sidekiq_job['args'].first)['payload']).deep_symbolize_keys }
  let(:sidekiq_params) { JSON.parse(sidekiq_job['args'].first).deep_symbolize_keys }
  let(:remaining_requests) { 10 }
  let(:body) { JSON.load(last_response.body).deep_symbolize_keys }

  let(:authorization) { { 'permissions' => ['repository_settings_read', 'repository_build_create', 'repository_state_update'] } }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  before do
    ActiveRecord::Base.connection.execute("truncate requests cascade")
    ActiveRecord::Base.connection.execute("truncate repositories cascade")
    allow(Travis::Features).to receive(:owner_active?).and_return(true)
  end

  after do
    Sidekiq::Queues['build_requests'].clear
  end

  let(:login_required) do
    {
      '@type': 'error',
      error_type: 'login_required',
      error_message: 'login required'
    }
  end

  let(:insufficient_access) do
    {
      '@type': 'error',
      error_type: 'insufficient_access',
      error_message: 'operation requires create_request access to repository',
      permission: 'create_request',
      resource_type: 'repository',
      repository: {
        '@href': "/v3/repo/#{repo.id}",
        '@representation': 'minimal',
        '@type': 'repository',
        id: repo.id,
        name: 'minimal',
        slug: 'svenfuchs/minimal'
      }
    }
  end

  let(:not_found) do
    {
      '@type': 'error',
      error_type: 'not_found',
      error_message: 'repository not found (or insufficient access)',
      resource_type: 'repository'
    }
  end

  let(:repo_inactive) do
    {
      '@type': 'error',
      error_type: 'repository_inactive',
      error_message: 'cannot create requests on an inactive repository',
      repository: {
        '@href': "/v3/repo/#{repo.id}",
        '@representation': 'minimal',
        '@type': 'repository',
        id: repo.id,
        name: 'minimal',
        slug: 'svenfuchs/minimal'
      }
    }
  end

  let(:request_limit_reached) do
    {
      '@type': 'error',
      error_type: 'request_limit_reached',
      error_message: 'request limit reached for resource',
      max_requests: 10,
      per_seconds: 3600,
      repository: {
        '@href': "/v3/repo/#{repo.id}",
        '@representation': 'minimal',
        '@type': 'repository',
        id: repo.id,
        name: 'minimal',
        slug: 'svenfuchs/minimal'
      }
    }
  end

  let(:missing_user) do
    {
      '@type': 'error',
      error_type: 'wrong_params',
      error_message: 'missing user'
    }
  end

  let(:repo_migrated) do
    {
      '@type': 'error',
      error_type: 'repo_migrated',
      error_message: 'This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com'
    }
  end

  let(:success) do
    {
      '@type': 'pending',
      resource_type: 'request',
      remaining_requests: remaining_requests,
      repository: {
        '@href': "/repo/#{repo.id}",
        '@representation': 'minimal',
        '@type': 'repository',
        id: repo.id,
        name: 'minimal',
        slug: 'svenfuchs/minimal'
      },
      request: compact(payload)
    }
  end

  let(:payload) do
    {
      repository: {
        id: repo.github_id,
        vcs_type: repo.vcs_type,
        owner_name: 'svenfuchs',
        name: 'minimal'
      },
      user: {
        id: repo.owner.id
      },
      id: request.id,
      message: nil,
      branch: 'master',
      sha: nil,
      tag_name: nil,
      merge_mode: nil,
      config: nil,
      configs: nil
    }
  end

  def compact(hash)
    hash.reject { |_, value| value.nil? }.to_h
  end

  describe 'not authenticated' do
    before { post("/v3/repo/#{repo.id}/requests") }
    let(:authorization) { { 'permissions' =>[] } }

    it { expect(last_response.status).to be == 403 }
    it { expect(body).to eq login_required }
  end

  describe 'missing repository, authenticated' do
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before { post("/v3/repo/9999999999/requests", {}, headers) }

    it { expect(last_response.status).to be == 404 }
    it { expect(body).to eq not_found }
  end

  describe 'existing repository, no push access' do

    let(:authorization) { { 'permissions' =>[] } }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before { post("/v3/repo/#{repo.id}/requests", {}, headers) }

    it { expect(last_response.status).to be == 403 }
    it { expect(body).to eq insufficient_access }
  end

  describe 'existing repository, owner in read-only mode' do
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before { allow(Travis::Features).to receive(:owner_active?).and_return(false) }
    before { post("/v3/repo/#{repo.id}/requests", {}, headers) }

    it { expect(last_response.status).to be == 404 }
  end

  describe 'private repository, no access' do
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before { repo.update_attribute(:private, true) }
    before { post("/v3/repo/#{repo.id}/requests", {}, headers) }

    it { expect(last_response.status).to be == 404 }
    it { expect(body).to eq not_found }
  end

  describe 'existing repository, push access' do
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    let(:params)  { {} }
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before { post("/v3/repo/#{repo.id}/requests", params, headers) }

    describe 'success' do
      it { expect(last_response.status).to be == 202 }
      it { expect(body).to eq success }
      it { expect(sidekiq_payload).to eq payload }
    end

    describe 'setting id has no effect' do
      let(:params) { { id: 42 } }
      it { expect(sidekiq_payload).to eq payload }
    end

    describe 'setting repository has no effect' do
      let(:params) { { repository: { id: 42 } }}
      it { expect(sidekiq_payload).to eq payload }
    end

    describe 'setting user has no effect' do
      let(:params) { { user: { id: 42 } }}
      it { expect(sidekiq_payload).to eq payload }
    end

    describe 'setting merge mode' do
      let(:params) { { merge_mode: 'replace' } }
      it { expect(sidekiq_payload).to eq payload.merge(merge_mode: 'replace') }
    end

    describe 'overriding config' do
      let(:params) { { config: { script: 'true' } } }
      it { expect(sidekiq_payload).to eq payload.merge(config: '{"script":"true"}', configs: [config: '{"script":"true"}', mode: nil]) }
    end

    describe 'overriding message' do
      let(:params) { { message: 'it' } }
      it { expect(sidekiq_payload).to eq payload.merge(message: params[:message]) }
    end

    describe 'overriding branch' do
      let(:params) { { branch: 'it' } }
      it { expect(sidekiq_payload).to eq payload.merge(branch: params[:branch]) }
    end

    describe 'overriding branch (in request)' do
      let(:params) { { request: { branch: 'it' } } }
      it { expect(sidekiq_payload).to eq payload.merge(branch: params[:request][:branch]) }
    end

    describe 'overriding branch (with request prefix)' do
      let(:params) { { 'request.branch': 'it' } }
      it { expect(sidekiq_payload).to eq payload.merge(branch: params[:'request.branch']) }
    end

    describe 'overriding branch (with request type)' do
      let(:params) { { '@type': 'request', branch: 'it' } }
      it { expect(sidekiq_payload).to eq payload.merge(branch: params[:branch]) }
    end

    describe 'overriding branch (with wrong type, has no effect)' do
      let(:params) { { '@type': 'repository', branch: 'it' } }
      it { expect(sidekiq_payload).to eq payload }
    end

    describe 'overriding sha' do
      let(:params) { { sha: 'it' } }
      it { expect(sidekiq_payload).to eq payload.merge(sha: params[:sha]) }
    end

    describe 'overriding sha (in request)' do
      let(:params) { { request: { sha: 'it' } } }
      it { expect(sidekiq_payload).to eq payload.merge(sha: params[:request][:sha]) }
    end

    describe 'overriding sha (with request prefix)' do
      let(:params) { { 'request.sha': 'it' } }
      it { expect(sidekiq_payload).to eq payload.merge(sha: params[:'request.sha']) }
    end

    describe 'overriding sha (with request type)' do
      let(:params) { { '@type': 'request', sha: 'it' } }
      it { expect(sidekiq_payload).to eq payload.merge(sha: params[:sha]) }
    end

    describe 'overriding tag_name (in request)' do
      let(:params) { { request: { tag_name: 'v1.0' } } }
      it { expect(sidekiq_payload).to eq payload.merge(tag_name: params[:request][:tag_name]) }
    end

    describe 'when the repository is inactive' do
      before { repo.update!(active: false) }
      before { post("/v3/repo/#{repo.id}/requests", {}, headers) }

      it { expect(last_response.status).to be == 406 }
      it { expect(body).to eq repo_inactive }
    end

    describe 'when request limit is reached' do
      before { 10.times { repo.requests.create(event_type: 'api') } }
      before { post("/v3/repo/#{repo.id}/requests", {}, headers) }

      it { expect(last_response.status).to be == 429 }
      it { expect(body).to eq request_limit_reached }
    end

    describe 'overrides default request limit if included in repository.settings' do
      let(:remaining_requests) { 1 }
      before { repo.update_attribute(:settings, { api_builds_rate_limit: 12 }.to_json) }
      before { 10.times { repo.requests.create(event_type: 'api') } }
      before { post("/v3/repo/#{repo.id}/requests", {}, headers) }

      it { expect(last_response.status).to be == 202 }
      it { expect(body).to eq success }
    end

    describe 'passing the token in params' do
      let(:params) { { request: { token: 'foo-bar' } } }
      it { expect(sidekiq_params[:credentials]).to eq token: 'foo-bar' }
    end
  end

  describe 'existing repository, application with full access' do
    let(:app_name)   { 'travis-it' }
    let(:app_secret) { '12345678' }
    let(:sign_opts)  { "a=#{app_name}" }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts) }
    let(:headers)    { { 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}" } }
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret } } }
    before { post("/v3/repo/#{repo.id}/requests", params, headers) }

    describe 'without setting user' do
      let(:params) { {} }
      it { expect(last_response.status).to be == 400 }
      it { expect(body).to eq missing_user }
    end

    describe 'setting user' do
      let(:params) { { user: { id: 1 } } }
      it { expect(last_response.status).to be == 202 }
      it { expect(sidekiq_payload).to eq payload } # not sure this is accurate ...
    end

    describe 'setting branch' do
      let(:params) {{ user: { id: repo.owner.id }, branch: 'it' }}
      it { expect(last_response.status).to be == 202 }
      it { expect(sidekiq_payload).to eq payload.merge(branch: 'it') }
    end
  end

  context do
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }

    describe 'repo migrating' do
      before { repo.update(migration_status: "migrating") }
      before { post("/v3/repo/#{repo.id}/requests", {}, headers) }

      it { expect(last_response.status).to be == 403 }
      it { expect(body).to eq repo_migrated }
    end

    describe 'repo migrating' do
      before { repo.update(migration_status: "migrated") }
      before { post("/v3/repo/#{repo.id}/deactivate", {}, headers) }

      it { expect(last_response.status).to be == 403 }
      it { expect(body).to eq repo_migrated }
    end
  end
end
