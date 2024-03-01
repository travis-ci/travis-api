describe 'v1 logs', auth_helpers: true, api_version: :v1, set_app: true do
  let(:user)  { FactoryBot.create(:user) }
  let(:repo)  { Repository.by_slug('svenfuchs/minimal').first }
  let(:build) { repo.builds.first }
  let(:job)   { Job.where(source_id: build.id).first }
  let(:log)   { double(id: 1) }

  let(:log_url) { "#{Travis.config[:logs_api][:url]}/logs/1?by=id&source=api" }
  before do
    stub_request(:get, log_url).to_return(status: 200, body: %({"job_id": #{job.id}, "content": "content"}))
    stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 401)
    repository = Travis::API::V3::Models::Repository.find(repo.id)
    repository.user_settings.update(:job_log_time_based_limit, true)
    repository.save!
  end

  describe 'in public mode, with a private repo', mode: :public, repo: :private do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: [200, 307], type: :text, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: [200, 307], type: :text, empty: false }
      it(:without_permission) { should auth status: [200, 307], type: :text, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in private mode, with a public repo', mode: :private, repo: :public do
    describe 'GET /logs/%{log.id}' do
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
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: [200, 307], type: :text, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: [200, 307], type: :text, empty: false }
      it(:without_permission) { should auth status: [200, 307], type: :text, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: [200, 307], type: :text, empty: false }
    end
  end
end
