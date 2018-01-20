describe 'Auth requests', auth_helpers: true, site: :org, api_version: :v1, set_app: true do
  let(:user)    { FactoryBot.create(:user) }
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:request) { repo.requests.first }

  # TODO
  # post '/requests'

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /requests?repository_id=%{repo.id}' do
      it(:with_permission)    { should auth status: 406 } # no v1 serializer for requests
      it(:without_permission) { should auth status: 406 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 406 }
    end

    describe 'GET /requests/%{request.id}' do
      it(:with_permission)    { should auth status: 406 } # no v1 serializer for requests
      it(:without_permission) { should auth status: 406 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 406 }
    end
  end
end
