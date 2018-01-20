describe 'Auth jobs', auth_helpers: true, site: :org, api_version: :v1, set_app: true do
  let(:user) { FactoryBot.create(:user) }
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }
  let(:job)  { repo.builds.first.matrix.first }

  # accesses the logs api for the job's log
  let(:log_url) { "#{Travis.config[:logs_api][:url]}/logs/#{job.id}?by=job_id&source=api" }
  before { stub_request(:get, log_url).to_return(status: 200, body: %({"job_id": #{job.id}, "content": "content"})) }
  before { Job.update_all(state: :started) }

  # TODO
  # post '/jobs/:id/cancel'
  # post '/jobs/:id/restart'
  # patch '/jobs/:id/log'

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /jobs' do
      it(:with_permission)    { should auth status: 200, empty: false }
      it(:without_permission) { should auth status: 200, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, empty: false }
    end

    describe 'GET /jobs/%{job.id}' do
      it(:with_permission)    { should auth status: 200, empty: false }
      it(:without_permission) { should auth status: 200, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, empty: false }
    end

    describe 'GET /jobs/%{job.id}/log' do
      it(:with_permission)    { should auth status: 200, empty: false }
      it(:without_permission) { should auth status: 200, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, empty: false }
    end
  end
end
