describe 'Auth settings/ssh_key', auth_helpers: true, site: :org, api_version: :v2, set_app: true do
  let(:user) { FactoryBot.create(:user) }
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }

  # before(:all) { SslKey.create(repository_id: 1) }
  # before { SslKey.update_all(repository_id: repo.id) }

  before do
    settings = repo.settings
    record = settings.create(:ssh_key, description: 'key for my repo', value: TEST_PRIVATE_KEY)
    settings.save
  end

  # TODO patch /settings/ssh_key/:repo_id
  # TODO delete /settings/ssh_key/:repo_id

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /settings/ssh_key/%{repo.id}' do
      it(:authenticated)   { should auth status: 200, empty: false }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end
  end
end
