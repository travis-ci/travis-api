describe 'Auth users', auth_helpers: true, site: :org, api_version: :v2, set_app: true do
  let(:user) { User.first }
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }

  # TODO put /users/
  # TODO put /users/:id ?
  # TODO post /users/sync

  describe 'in public', mode: :public do
    describe 'GET /users' do
      it(:authenticated)   { should auth status: 200, empty: false }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end

    describe 'GET /users/permissions' do
      it(:authenticated)   { should auth status: 200, empty: false }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end

    describe 'GET /users/%{user.id}' do
      it(:authenticated)   { should auth status: 200, empty: false }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end

    describe 'GET /users/0' do
      it(:authenticated)   { should auth status: 404 }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end
  end
end
