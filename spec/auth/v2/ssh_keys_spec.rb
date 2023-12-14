describe 'v2 settings/ssh_key', auth_helpers: true, api_version: :v2, set_app: true do
  let(:user) { FactoryBot.create(:user) }
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 401) }
  # before(:all) { SslKey.create(repository_id: 1) }
  # before { SslKey.update_all(repository_id: repo.id) }

  before do
    settings = repo.settings
    record = settings.create(:ssh_key, description: 'key for my repo', value: TEST_PRIVATE_KEY)
    settings.save
  end

  # TODO patch /settings/ssh_key/:repo_id
  # TODO delete /settings/ssh_key/:repo_id

  describe 'in public mode, with a private repo', mode: :public, repo: :private do
    describe 'GET /settings/ssh_key/%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 } # was 404? but also, the pro-api specs for this endpoint are somewhat weird
    end
  end

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /settings/ssh_key/%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in private mode, with a public repo', mode: :private, repo: :public do
    describe 'GET /settings/ssh_key/%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
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
    describe 'GET /settings/ssh_key/%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 } # was 404? but also, the pro-api specs for this endpoint are somewhat weird
    end
  end

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /settings/ssh_key/%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end
end
