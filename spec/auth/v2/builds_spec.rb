describe 'v2 builds', auth_helpers: true, api_version: :v2, set_app: true do
  let(:user)  { FactoryBot.create(:user) }
  let(:repo)  { Repository.by_slug('svenfuchs/minimal').first }
  let(:build) { repo.builds.first }

  # TODO
  # post '/builds/:id/cancel'
  # post '/builds/:id/restart'

  describe 'in public mode, with a private repo', mode: :public, repo: :private do
    describe 'GET /builds' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds?running=true' do
      before { build.update(state: :started) }
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds?repository_id=%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds?repository_id=%{repo.id}&branches=%{build.branch}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds/%{build.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /builds' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds?running=true' do
      before { build.update(state: :started) }
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds?repository_id=%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds?repository_id=%{repo.id}&branches=%{build.branch}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds/%{build.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in private mode, with a public repo', mode: :private, repo: :public do
    describe 'GET /builds' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds?running=true' do
      before { build.update(state: :started) }
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds?repository_id=%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds?repository_id=%{repo.id}&branches=%{build.branch}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds/%{build.id}' do
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
    describe 'GET /builds' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds?running=true' do
      before { build.update(state: :started) }
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds?repository_id=%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds?repository_id=%{repo.id}&branches=%{build.branch}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /builds/%{build.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /builds' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: true }
    end

    describe 'GET /builds?running=true' do
      before { build.update(state: :started) }
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: true }
    end

    describe 'GET /builds?repository_id=%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /builds?repository_id=%{repo.id}&branches=%{build.branch}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /builds/%{build.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end
  end
end
