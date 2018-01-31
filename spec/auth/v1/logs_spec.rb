describe 'Auth logs', auth_helpers: true, api_version: :v1, set_app: true do
  let(:user)  { FactoryBot.create(:user) }
  let(:repo)  { Repository.by_slug('svenfuchs/minimal').first }
  let(:build) { repo.builds.first }
  let(:job)   { build.matrix.first }
  let(:log)   { stub(id: 1) }

  let(:log_url) { "#{Travis.config[:logs_api][:url]}/logs/1?by=id&source=api" }
  before { stub_request(:get, log_url).to_return(status: 200, body: %({"job_id": #{job.id}, "content": "content"})) }

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: [200, 307], empty: false }
      it(:without_permission) { should auth status: [200, 307], empty: false }
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
      it(:with_permission)    { should auth status: [200, 307], empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: [200, 307], empty: false }
      it(:without_permission) { should auth status: [200, 307], empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: [200, 307], empty: false }
    end
  end
end
