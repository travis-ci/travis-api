describe 'v2.1 jobs', auth_helpers: true, api_version: :'v2.1', set_app: true do
  let(:user) { FactoryBot.create(:user) }
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }
  let(:job)  { repo.builds.first.matrix.first }
  let(:log)  { %({"job_id": #{job.id}, "content": "content"}) }

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

  let(:archived_content) { "$ git clean -fdx\nRemoving Gemfile.lock\n$ git fetch" }

  let(:log_url) { "#{Travis.config[:logs_api][:url]}/logs/1?by=id&source=api" }

  before do
    remote = double('remote')
    allow(Travis::RemoteLog::Remote).to receive(:new).and_return(remote)
    allow(remote).to receive(:find_by_job_id).and_return(Travis::RemoteLog.new(log_from_api))
    allow(remote).to receive(:find_by_id).and_return(Travis::RemoteLog.new(log_from_api))
    allow(remote).to receive(:fetch_archived_log_content).and_return(archived_content)
  end

  before { Job.update_all(state: :started) }

  # TODO
  # post '/jobs/:id/cancel'
  # post '/jobs/:id/restart'
  # patch '/jobs/:id/log'

  describe 'in public mode, with a private repo', mode: :public, repo: :private do
    describe 'GET /jobs' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: true }
    end

    describe 'GET /jobs/%{job.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 404 }
    end

    describe 'GET /jobs/%{job.id}/log' do
      it(:with_permission)    { should auth status: 200, type: [:json, :text], empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 404 }
    end
  end

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /jobs' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /jobs/%{job.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /jobs/%{job.id}/log' do
      it(:with_permission)    { should auth status: 200, type: [:json, :text], empty: false }
      it(:without_permission) { should auth status: 200, type: [:json, :text], empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: [:json, :text], empty: false }
    end
  end

  describe 'in private mode, with a public repo', mode: :private, repo: :public do
    describe 'GET /jobs' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /jobs/%{job.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /jobs/%{job.id}/log' do
      it(:with_permission)    { should auth status: 200, type: [:json, :text], empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  # +----------------------------------------------------+
  # |                                                    |
  # |   !!! THE ORIGINAL BEHAVIOUR ... DON'T TOUCH !!!   |
  # |                                                    |
  # +----------------------------------------------------+

  describe 'in private mode, with a private repo', mode: :private, repo: :private do
    describe 'GET /jobs' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /jobs/%{job.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /jobs/%{job.id}/log' do
      it(:with_permission)    { should auth status: 200, type: [:json, :text], empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /jobs' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /jobs/%{job.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /jobs/%{job.id}/log' do
      it(:with_permission)    { should auth status: 200, type: [:json, :text], empty: false }
      it(:without_permission) { should auth status: 200, type: [:json, :text], empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: [:json, :text], empty: false }
    end
  end
end
