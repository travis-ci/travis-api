describe 'v2.1 settings/env_vars', auth_helpers: true, api_version: :'v2.1', set_app: true do
  let(:user) { FactoryBot.create(:user) }
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }

  before { repo.settings.tap { |s| s.env_vars.create(name: 'FOO', value: 'foo') && s.save } }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 401) }
  # TODO get /settings/env_vars/:id
  # TODO post /settings/env_vars/
  # TODO patch /settings/env_vars/:id
  # TODO delete /settings/env_vars/:id

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /settings/env_vars?repository_id=%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in public mode, with a private repo', mode: :public, repo: :private do
    describe 'GET /settings/env_vars?repository_id=%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in private mode, with a public repo', mode: :private, repo: :public do
    describe 'GET /settings/env_vars?repository_id=%{repo.id}' do
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
    describe 'GET /settings/env_vars?repository_id=%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /settings/env_vars?repository_id=%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end
end
