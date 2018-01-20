describe 'Auth hooks', auth_helpers: true, site: :org, api_version: :v1, set_app: true do
  let(:user) { FactoryBot.create(:user) }
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }

  # TODO put /hooks/:id

  describe 'in private mode, with a private repo', mode: :private, repo: :private do
    describe 'GET /hooks' do
      it(:with_permission)    { should auth status: 200, empty: false }
      it(:without_permission) { should auth status: 200, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end



  # +-------------------------------------------------------------+
  # |                                                             |
  # |   !!! BELOW IS THE ORIGINAL BEHAVIOUR ... DON'T TOUCH !!!   |
  # |                                                             |
  # +-------------------------------------------------------------+

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /hooks' do
      it(:with_permission)    { should auth status: 200, empty: false }
      it(:without_permission) { should auth status: 200, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end
end
