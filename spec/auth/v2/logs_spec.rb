describe 'Auth logs', auth_helpers: true, api_version: :v2, set_app: true do
  let(:user)  { FactoryBot.create(:user) }
  let(:repo)  { Repository.by_slug('svenfuchs/minimal').first }
  let(:build) { repo.builds.first }
  let(:job)   { build.matrix.first }

  let(:log_url) { "#{Travis.config[:logs_api][:url]}/logs/1?by=id&source=api" }
  before { stub_request(:get, log_url).to_return(status: 200, body: %({"job_id": #{job.id}, "content": "content"})) }

  # +----------------------------------------------------+
  # |                                                    |
  # |   !!! THE ORIGINAL BEHAVIOUR ... DON'T TOUCH !!!   |
  # |                                                    |
  # +----------------------------------------------------+

  describe 'in private mode, with a private repo', mode: :private, repo: :private do
    describe 'GET /logs/1' do
      it(:with_permission)    { should auth status: 200, empty: false }
      xit(:without_permission) { should auth status: 404 } # TODO this is not ok
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /logs/1' do
      it(:with_permission)    { should auth status: 200, empty: false }
      it(:without_permission) { should auth status: 200, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, empty: false }
    end
  end
end
