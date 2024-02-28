describe 'Jobs', set_app: true do
  let!(:jobs) {[
    FactoryBot.create(:test, :number => '3.1', :queue => 'builds.common'),
    FactoryBot.create(:test, :number => '3.2', :queue => 'builds.common')
  ]}
  let(:job) { jobs.first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  let :log_from_api do
    {
      aggregated_at: Time.now,
      archive_verified: true,
      archived_at: Time.now,
      archiving: false,
      content: 'hello world. this is a really cool log',
      created_at: Time.now,
      id: 1,
      job_id: job.id,
      purged_at: nil,
      removed_at: nil,
      removed_by_id: nil,
      updated_at: Time.now
    }
  end

  let(:archived_log_url) { 'https://s3.amazonaws.com/STUFFS' } # bogus URL unused anywhere
  let(:archived_content) { "$ git clean -fdx\nRemoving Gemfile.lock\n$ git fetch" }

  let(:log_url) { "#{Travis.config[:logs_api][:url]}/logs/1?by=id&source=api" }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  before do
    remote = double('remote')
    allow(Travis::RemoteLog::Remote).to receive(:new).and_return(remote)
    allow(remote).to receive(:find_by_job_id).and_return(Travis::RemoteLog.new(log_from_api))
    allow(remote).to receive(:find_by_id).and_return(Travis::RemoteLog.new(log_from_api))
    allow(remote).to receive(:fetch_archived_url).and_return(archived_log_url)
    allow(remote).to receive(:fetch_archived_log_content).and_return(archived_content)
    allow(remote).to receive(:write_content_for_job_id).and_return(remote)
    allow(remote).to receive(:send).and_return(remote) # ignore attribute updates
  end

  before do
    Travis.config.billing.url = 'http://localhost:9292/'
    Travis.config.billing.auth_key = 'secret'

    stub_request(:post, /http:\/\/localhost:9292\/(users|organizations)\/(.+)\/authorize_build/).to_return(
      body: MultiJson.dump(allowed: true, rejection_code: nil)
    )
  end

  after do
    Travis.config.billing.url = nil
    Travis.config.billing.auth_key = nil
  end

  it '/jobs?queue=builds.common' do
    skip('querying with a queue does not appear to be used anymore')
    response = get '/jobs', { queue: 'builds.common' }, headers
    expect(response).to deliver_json_for(Job.queued('builds.common'), version: 'v2')
  end

  it '/jobs/:id' do
    response = get "/jobs/#{job.id}", {}, headers
    expect(response.status).to eq(200)
    expected = Travis::Api::Serialize.data(job, version: 'v2')
    expected.delete('log_id')
    parsed = MultiJson.decode(response.body)
    parsed['job'].delete('log_id')
    expect(parsed).to eq(expected)
  end

  it "doesn't allow access with travis-token in private mode and with private repo" do
    Travis.config.public_mode = false
    Travis.config.host = 'api.travis-ci.com'
    user = User.first
    Permission.create(push: true, pull: true, admin: true, repository: job.repository, user: user)

    job.update_column(:private, true)
    job.repository.update_column(:private, true)

    token = user.tokens.first.token

    response = get "/jobs/#{job.id}?token=#{token}", {}, 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2.1+json'
    expect(response.status).to eq(403)
  end

  context 'GET /jobs/:job_id/log.txt' do
    it 'returns the log' do
      response = get("/jobs/#{job.id}/log.txt")
      expect(response.status).to eq(200)
    end

    it 'returns 406 (Unprocessable) if Accept header requests JSON' do
      response = get("/jobs/#{job.id}/log.txt", {}, headers)
      expect(response.status).to eq(406)
    end

    context 'when log is archived' do
      it 'returns the log' do
        remote = double('remote')
        remote_log = double('remote log')
        expect(remote_log).to receive(:archived?).and_return(true)
        allow(remote_log).to receive(:removed_at).and_return(nil)
        allow(remote_log).to receive(:archived_log_content).and_return(archived_content)
        allow(remote).to receive(:find_by_job_id).and_return(remote_log)
        allow(remote).to receive(:fetch_archived_log_content).and_return(archived_content)
        expect(Travis::RemoteLog::Remote).to receive(:new).and_return(remote)
        stub_request(:get, "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id&source=api")
          .to_return(
            status: 200,
            body: JSON.dump(
              content: 'the log',
              archived_at: Time.now,
              archive_verified: true
            )
          )
        response = get(
          "/jobs/#{job.id}/log.txt",
          {},
          { 'HTTP_ACCEPT' => 'text/plain; version=2' }
        )
        expect(response.status).to eq(200)
      end
    end

    context 'when log is missing' do
      it 'returns the log retrieved from s3' do
        stub_request(:get, "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id&source=api")
          .to_return(status: 404, body: '')
        response = get(
          "/jobs/#{job.id}/log.txt",
          {},
          { 'HTTP_ACCEPT' => 'text/plain; version=2' }
        )
        expect(response.status).to eq(200)
      end
    end

    context 'with chunked log requested' do
      it 'succeeds' do
        stub_request(:get, "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id&source=api")
          .to_return(
            status: 200,
            body: JSON.dump(
              content: 'fla flah flooh',
              aggregated_at: Time.now,
              archived_at: Time.now,
              archive_verified: true
            )
          )
        response = get(
          "/jobs/#{job.id}/log",
          {},
          { 'HTTP_ACCEPT' => 'application/json; version=2; chunked=true' }
        )
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'PATCH /jobs/:job_id/log' do
    let(:user) { User.where(login: 'svenfuchs').first }
    let(:token) do
      Travis::Api::App::AccessToken.create(user: user, app_id: -1)
    end

    before :each do
      headers.merge! 'HTTP_AUTHORIZATION' => "token #{token}"
    end

    context 'when user does not have push permissions' do
      before :each do
        user.permissions.create!(
          repository_id: job.repository.id,
          push: false
        )
      end

      it 'returns status 401' do
        stub_request(
          :get,
          "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id&source=api"
        ).to_return(status: 200, body: JSON.dump(content: 'flah'))
        response = patch(
          "/jobs/#{job.id}/log",
          { reason: 'Because reason!' },
          headers
        )
        expect(response.status).to eq 401
      end
    end

    context 'when user has push permission' do
      context 'when job is not finished' do
        before :each do
          allow(job).to receive(:finished?).and_return false
          user.permissions.create!(
            repository_id: job.repository.id, push: true
          )
        end

        it 'returns status 409' do
          stub_request(
            :get,
            "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id&source=api"
          ).to_return(
            status: 200,
            body: JSON.dump(content: 'flah', job_id: job.id)
          )
          response = patch(
            "/jobs/#{job.id}/log", { reason: 'Because reason!' }, headers
          )
          expect(response.status).to eq 409
        end
      end

      context 'when job is finished' do
        let(:finished_job) { FactoryBot.create(:test, state: 'passed') }

        before :each do
          user.permissions.create!(
            repository_id: finished_job.repository.id, push: true
          )
        end

        it 'returns status 200' do
          stub_request(
            :get,
            "#{Travis.config.logs_api.url}/logs/#{finished_job.id}?by=job_id&source=api"
          ).to_return(
            status: 200,
            body: JSON.dump(content: 'flah', job_id: finished_job.id)
          )
          stub_request(
            :put,
            "#{Travis.config.logs_api.url}/logs/#{finished_job.id}?removed_by=#{user.id}&source=api"
          ).to_return(
            status: 200,
            body: JSON.dump(content: '', job_id: finished_job.id)
          )
          response = patch(
            "/jobs/#{finished_job.id}/log",
            { reason: 'Because reason!' },
            headers
          )
          expect(response.status).to eq 200
        end
      end
    end
  end

  describe 'POST /jobs/:id/cancel' do
    let(:user)    { User.where(login: 'svenfuchs').first }
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }

    before {
      headers.merge! 'HTTP_AUTHORIZATION' => "token #{token}"
      user.permissions.create!(repository_id: job.repository.id, :push => true, :pull => true)
    }

    context 'when user does not have rights to cancel the job' do
      before { user.permissions.destroy_all }

      it 'responds with 403' do
        response = post "/jobs/#{job.id}/cancel", {}, headers
        expect(response.status).to eq(403)
      end

      context 'and tries to enqueue cancel event for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, job.repository.owner) }

        it 'responds with 403' do
          response = post "/jobs/#{job.id}/cancel", {}, headers
          expect(response.status).to eq(403)
        end
      end
    end

    context 'when job is not cancelable' do
      before { job.update_attribute(:state, 'passed') }

      it 'responds with 422' do
        response = post "/jobs/#{job.id}/cancel", {}, headers
        expect(response.status).to eq(422)
      end

      context 'and tries to enqueue cancel event for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, job.repository.owner) }

        it 'responds with 422' do
          response = post "/jobs/#{job.id}/cancel", {}, headers
          expect(response.status).to eq(422)
        end
      end
    end

    context 'when job can be canceled' do
      before do
        job.update_attribute(:state, 'created')
      end

      context 'and enqueues cancel event for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, job.repository.owner) }

        it 'cancels the job' do
          expect(::Sidekiq::Client).to receive(:push)
          post "/jobs/#{job.id}/cancel", {}, headers
        end

        it 'responds with 204' do
          expect(::Sidekiq::Client).to receive(:push)
          response = post "/jobs/#{job.id}/cancel", {}, headers
          expect(response.status).to eq(204)
        end
      end
    end
  end

  describe 'POST /jobs/:id/restart' do
    let(:user)  { User.where(login: 'svenfuchs').first }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }

    before {
      headers.merge! 'HTTP_AUTHORIZATION' => "token #{token}"
      user.permissions.create!(repository_id: job.repository.id, :pull => true, :push => true)
    }

    context 'when restart is not acceptable' do
      before { user.permissions.destroy_all }

      it 'responds with 400' do
        response = post "/jobs/#{job.id}/restart", {}, headers
        expect(response.status).to eq(400)
      end

      context 'when enqueuing for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, job.repository.owner) }

        it 'responds with 400' do
          response = post "/jobs/#{job.id}/restart", {}, headers
          expect(response.status).to eq(400)
        end
      end
    end

    context 'when the repo is migrating' do
      before { job.repository.update(migration_status: "migrating") }
      before { post "/jobs/#{job.id}/restart", {}, headers }
      it { expect(last_response.status).to eq(403) }
    end

    context 'when the repo is migrated' do
      before { job.repository.update(migration_status: "migrated") }
      before { post "/jobs/#{job.id}/restart", {}, headers }
      it { expect(last_response.status).to eq(403) }
    end

    context 'when job passed' do
      before { job.update_attribute(:state, 'passed') }

      context 'Enqueues restart event for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, job.repository.owner) }

        it 'restarts the job' do
          expect(::Sidekiq::Client).to receive(:push)
          response = post "/jobs/#{job.id}/restart", {}, headers
          expect(response.status).to eq(202)
        end
        it 'sends the correct response body' do
          expect(::Sidekiq::Client).to receive(:push)
          response = post "/jobs/#{job.id}/restart", {}, headers
          body = JSON.parse(response.body)
          expect(body).to eq({"result"=>true, "flash"=>[{"notice"=>"The job was successfully restarted."}]})
        end

      end
    end
  end
end
