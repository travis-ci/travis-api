describe 'v2.1 logs', auth_helpers: true, api_version: :'v2.1', set_app: true do
  let(:user)  { FactoryBot.create(:user) }
  let(:repo)  { Repository.by_slug('svenfuchs/minimal').first }
  let(:build) { repo.builds.first }
  let(:job)   { build.matrix.first }
  let(:log)   { double(id: 1) }

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
    repository = Travis::API::V3::Models::Repository.find(repo.id)
    repository.user_settings.update(:job_log_time_based_limit, true)
    repository.save!
    stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 401)
  end

  describe 'in public mode, with a private repo', mode: :public, repo: :private do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: 200, type: [:json, :text], empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 404 }
    end
  end

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: 200, type: [:json, :text], empty: false }
      it(:without_permission) { should auth status: 200, type: [:json, :text], empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: [:json, :text], empty: false }
    end
  end

  describe 'in private mode, with a public repo', mode: :private, repo: :public do
    describe 'GET /logs/%{log.id}' do
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
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: 200, type: [:json, :text], empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: 200, type: [:json, :text], empty: false }
      it(:without_permission) { should auth status: 200, type: [:json, :text], empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: [:json, :text], empty: false }
    end
  end
end
