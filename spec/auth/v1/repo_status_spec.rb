describe 'v1 status', auth_helpers: true, api_version: :v1, set_app: true do
  let(:user)  { FactoryBot.create(:user) }
  let(:build) { repo.builds.first }

  def repo
    @repo ||= Repository.by_slug('svenfuchs/minimal').first
  end

  before(:all) { SslKey.create(repository_id: repo.id) }
  before { SslKey.update_all(repository_id: repo.id) }

  # TODO
  # patch '/repos/:id/settings'
  # post '/repos/:id/key' }
  # delete '/:repository_id/caches'
  # post '/:owner_name/:name/key'

  describe 'in public mode, with a private repo', mode: :public, repo: :private do
    describe 'GET /repos/%{user.login}.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 406 }
    end

    describe 'GET /repos/%{user.login}.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 406 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 406 }
    end

    describe 'GET /repos/%{repo.id}/cc.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 404 }
    end

    describe 'GET /repos/%{repo.slug}/cc.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 404 }
    end

    describe 'GET /repos/%{repo.id}/cc.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 404 }
    end

    describe 'GET /repos/%{repo.slug}/cc.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 404 }
    end

    describe 'GET /repos/%{repo.slug}.png' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept */*' do
      let(:accept) { '*/*' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept application/json' do
      let(:accept) { 'application/json' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept image/png' do
      let(:accept) { 'image/png' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept image/svg+xml' do
      let(:accept) { 'image/svg+xml' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.svg' }
    end

    describe 'GET /repos/%{repo.slug}.svg?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.svg' }
    end

    describe 'GET /repos/%{repo.slug}.svg' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.svg' }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :img, file: 'unknown.svg' }
    end

    describe 'GET /repos/%{repo.slug}/builds.atom' do
      it(:with_permission)    { should auth status: 200, type: :atom, empty: false }
      it(:without_permission) { should auth status: 406 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 406 }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept */*' do
      let(:accept) { '*/*' }
      it(:with_permission)    { should auth status: 403 }
      it(:without_permission) { should auth status: 403 }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept application/json' do
      let(:accept) { 'application/json' }
      it(:with_permission)    { should auth status: 403 }
      it(:without_permission) { should auth status: 403 }
    end
  end

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /repos/%{user.login}.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 200, type: :xml, empty: false }
    end

    describe 'GET /repos/%{user.login}.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 200, type: :xml, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :xml, empty: false }
    end

    describe 'GET /repos/%{repo.id}/cc.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 200, type: :xml, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :xml, empty: false }
    end

    describe 'GET /repos/%{repo.slug}/cc.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 200, type: :xml, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :xml, empty: false }
    end

    describe 'GET /repos/%{repo.id}/cc.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 200, type: :xml, empty: false }
    end

    describe 'GET /repos/%{repo.slug}/cc.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 200, type: :xml, empty: false }
    end

    describe 'GET /repos/%{repo.slug}.png' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.png' }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :img, file: 'passing.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept */*' do
      let(:accept) { '*/*' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept application/json' do
      let(:accept) { 'application/json' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept image/png' do
      let(:accept) { 'image/png' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.png' }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept image/svg+xml' do
      let(:accept) { 'image/svg+xml' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.svg' }
    end

    describe 'GET /repos/%{repo.slug}.svg?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.svg' }
    end

    describe 'GET /repos/%{repo.slug}.svg' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :img, file: 'passing.svg' }
    end

    describe 'GET /repos/%{repo.slug}/builds.atom' do
      it(:with_permission)    { should auth status: 200, type: :atom, empty: false }
      it(:without_permission) { should auth status: 200, type: :atom, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :atom, empty: false }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept */*' do
      let(:accept) { '*/*' }
      it(:with_permission)    { should auth status: 403 }
      it(:without_permission) { should auth status: 403 }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept application/json' do
      let(:accept) { 'application/json' }
      it(:with_permission)    { should auth status: 403 }
      it(:without_permission) { should auth status: 403 }
    end
  end

  describe 'in private mode, with a public repo', mode: :private, repo: :public do
    describe 'GET /repos/%{user.login}.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 406 }
    end

    describe 'GET /repos/%{user.login}.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 406 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/cc.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/cc.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/cc.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 404 }
    end

    describe 'GET /repos/%{repo.slug}/cc.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 404 }
    end

    describe 'GET /repos/%{repo.slug}.png' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept */*' do
      let(:accept) { '*/*' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept application/json' do
      let(:accept) { 'application/json' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept image/png' do
      let(:accept) { 'image/png' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept image/svg+xml' do
      let(:accept) { 'image/svg+xml' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.svg' }
    end

    describe 'GET /repos/%{repo.slug}.svg?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.svg' }
    end

    describe 'GET /repos/%{repo.slug}.svg' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.svg' }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds.atom' do
      it(:with_permission)    { should auth status: 200, type: :atom, empty: false }
      it(:without_permission) { should auth status: 406 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept */*' do
      let(:accept) { '*/*' }
      it(:with_permission)    { should auth status: 403 }
      it(:without_permission) { should auth status: 403 }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept application/json' do
      let(:accept) { 'application/json' }
      it(:with_permission)    { should auth status: 403 }
      it(:without_permission) { should auth status: 403 }
    end
  end

  # +----------------------------------------------------+
  # |                                                    |
  # |   !!! THE ORIGINAL BEHAVIOUR ... DON'T TOUCH !!!   |
  # |                                                    |
  # +----------------------------------------------------+

  describe 'in private mode, with a private repo', mode: :private, repo: :private do
    describe 'GET /repos/%{user.login}.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 406 }
    end

    describe 'GET /repos/%{user.login}.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 406 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/cc.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/cc.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/cc.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 404 }
    end

    describe 'GET /repos/%{repo.slug}/cc.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 404 }
    end

    describe 'GET /repos/%{repo.slug}.png' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept */*' do
      let(:accept) { '*/*' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept application/json' do
      let(:accept) { 'application/json' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept image/png' do
      let(:accept) { 'image/png' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.png' }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept image/svg+xml' do
      let(:accept) { 'image/svg+xml' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.svg' }
    end

    describe 'GET /repos/%{repo.slug}.svg?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.svg' }
    end

    describe 'GET /repos/%{repo.slug}.svg' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'unknown.svg' }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds.atom' do
      it(:with_permission)    { should auth status: 200, type: :atom, empty: false }
      it(:without_permission) { should auth status: 406 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept */*' do
      let(:accept) { '*/*' }
      it(:with_permission)    { should auth status: 403 }
      it(:without_permission) { should auth status: 403 }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept application/json' do
      let(:accept) { 'application/json' }
      it(:with_permission)    { should auth status: 403 }
      it(:without_permission) { should auth status: 403 }
    end
  end

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /repos/%{user.login}.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 200, type: :xml, empty: false }
    end

    describe 'GET /repos/%{user.login}.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 200, type: :xml, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :xml, empty: false }
    end

    describe 'GET /repos/%{repo.id}/cc.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 200, type: :xml, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :xml, empty: false }
    end

    describe 'GET /repos/%{repo.slug}/cc.xml' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 200, type: :xml, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :xml, empty: false }
    end

    describe 'GET /repos/%{repo.id}/cc.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 200, type: :xml, empty: false }
    end

    describe 'GET /repos/%{repo.slug}/cc.xml?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :xml, empty: false }
      it(:without_permission) { should auth status: 200, type: :xml, empty: false }
    end

    describe 'GET /repos/%{repo.slug}.png' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.png' }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :img, file: 'passing.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept */*' do
      let(:accept) { '*/*' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept application/json' do
      let(:accept) { 'application/json' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token} Accept image/png' do
      let(:accept) { 'image/png' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.png' }
    end

    describe 'GET /repos/%{repo.slug}.png?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.png' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.png' }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept image/svg+xml' do
      let(:accept) { 'image/svg+xml' }
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.svg' }
    end

    describe 'GET /repos/%{repo.slug}.svg?token=%{user.token}' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.svg' }
    end

    describe 'GET /repos/%{repo.slug}.svg' do
      it(:with_permission)    { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:without_permission) { should auth status: 200, type: :img, file: 'passing.svg' }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :img, file: 'passing.svg' }
    end

    describe 'GET /repos/%{repo.slug}/builds.atom' do
      it(:with_permission)    { should auth status: 200, type: :atom, empty: false }
      it(:without_permission) { should auth status: 200, type: :atom, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :atom, empty: false }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept */*' do
      let(:accept) { '*/*' }
      it(:with_permission)    { should auth status: 403 }
      it(:without_permission) { should auth status: 403 }
    end

    describe 'GET /repos/%{repo.slug}?token=%{user.token} Accept application/json' do
      let(:accept) { 'application/json' }
      it(:with_permission)    { should auth status: 403 }
      it(:without_permission) { should auth status: 403 }
    end
  end
end
