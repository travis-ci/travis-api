describe 'v1 jobs', auth_helpers: true, api_version: :v1, set_app: true do
  let(:user) { FactoryBot.create(:user) }
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }
  let(:job)  { repo.builds.first.matrix.first }
  let(:log)  { %({"job_id": #{job.id}, "content": "content"}) }

  let(:log_url) { "#{Travis.config[:logs_api][:url]}/logs/#{job.id}?by=job_id&source=api" }
  before { stub_request(:get, log_url).to_return(status: 200, body: log) }
  before { Job.update_all(state: :started) }

  # TODO
  # post '/jobs/:id/cancel'
  # post '/jobs/:id/restart'
  # patch '/jobs/:id/log'

  describe 'in public mode, with a private repo', mode: :public, repo: :private do
    describe 'GET /jobs' do
      it(:with_permission)    { should auth status: [200, 307], type: :json, empty: false }
      it(:without_permission) { should auth status: [200, 307], type: :json, empty: true }
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
      it(:with_permission)    { should auth status: [200, 307], type: :text, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /jobs' do
      it(:with_permission)    { should auth status: [200, 307], type: :json, empty: false }
      it(:without_permission) { should auth status: [200, 307], type: :json, empty: true  }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /jobs/%{job.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /jobs/%{job.id}/log' do
      it(:with_permission)    { should auth status: [200, 307], type: :text, empty: false }
      it(:without_permission) { should auth status: [200, 307], type: :text, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in private mode, with a public repo', mode: :private, repo: :public do
    describe 'GET /jobs' do
      it(:with_permission)    { should auth status: [200, 307], type: :json, empty: false }
      it(:without_permission) { should auth status: [200, 307], type: :json, empty: true }
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
      it(:with_permission)    { should auth status: [200, 307], type: :text, empty: false }
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
      it(:with_permission)    { should auth status: [200, 307], type: :text, empty: false }
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
      it(:with_permission)    { should auth status: [200, 307], type: :text, empty: false }
      it(:without_permission) { should auth status: [200, 307], type: :text, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: [200, 307], type: :text, empty: false }
    end
  end
end
