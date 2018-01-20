describe 'Auth settings/env_vars', auth_helpers: true, site: :org, api_version: :v1, set_app: true do
  let(:user) { FactoryBot.create(:user) }
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }

  before { repo.settings.tap { |s| s.env_vars.create(name: 'FOO', value: 'foo', private: true) && s.save } }

  # TODO get /settings/env_vars/:id
  # TODO post /settings/env_vars/
  # TODO patch /settings/env_vars/:id
  # TODO delete /settings/env_vars/:id

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /settings/env_vars?repository_id=%{repo.id}' do
      it(:with_permission)    { should auth status: 200, empty: false }
      it(:without_permission) { should auth status: 302 } # redirects to /repositories/settings/env_vars?repository_id=%{repo.id}, which returns a repo
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end
end
