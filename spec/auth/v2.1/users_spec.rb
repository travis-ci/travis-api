describe 'v2.1 users', auth_helpers: true, api_version: :'v2.1', set_app: true do
  let(:user) { User.first }
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }
  let!(:request) do
    WebMock.stub_request(:post, 'http://vcsfake.travis-ci.com/users/1/check_scopes')
      .to_return(
        status: 200,
        body: nil,
      )
  end
  before do
    Travis.config.vcs.url = 'http://vcsfake.travis-ci.com'
    Travis.config.vcs.token = 'vcs-token'
  end
  # TODO put /users/
  # TODO put /users/:id ?
  # TODO post /users/sync
  describe 'in public, with a private repo', mode: :public, repo: :private do
    describe 'GET /users' do
      it(:authenticated)      { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/permissions' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/%{user.id}' do
      it(:authenticated)      { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/0' do
      it(:authenticated)      { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end
  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /users' do
      it(:authenticated)      { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/permissions' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/%{user.id}' do
      it(:authenticated)      { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/0' do
      it(:authenticated)      { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end
  describe 'in private, with a public repo', mode: :private, repo: :public do
    describe 'GET /users' do
      it(:authenticated)      { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/permissions' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/%{user.id}' do
      it(:authenticated)      { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/0' do
      it(:authenticated)      { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end
  # +----------------------------------------------------+
  # |                                                    |
  # |   !!! THE ORIGINAL BEHAVIOUR ... DON'T TOUCH !!!   |
  # |                                                    |
  # +----------------------------------------------------+
  describe 'in private, with a private repo', mode: :private, repo: :private do
    describe 'GET /users' do
      it(:authenticated)      { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/permissions' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/%{user.id}' do
      it(:authenticated)      { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/0' do
      it(:authenticated)      { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end
  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /users' do
      it(:authenticated)      { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/permissions' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/%{user.id}' do
      it(:authenticated)      { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
    describe 'GET /users/0' do
      it(:authenticated)      { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end
end
