describe 'Auth users', auth_helpers: true, site: :org, api_version: :v1, set_app: true do
  let(:user) { User.first }
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }

  # TODO put /users/
  # TODO put /users/:id ?
  # TODO post /users/sync

  describe 'in private mode', mode: :private do
    describe 'GET /users' do
      it(:authenticated)   { should auth status: 200, empty: false }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end

    describe 'GET /users/permissions' do
      it(:authenticated)   { should auth status: 406} # no v1 serializer for permissions
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end

    describe 'GET /users/%{user.id}' do
      it(:authenticated)   { should auth status: 200, empty: false }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end

    describe 'GET /users/0' do
      it(:authenticated)   { should auth status: 302 } # redirects to /repos/users/0
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end
  end



  # +-------------------------------------------------------------+
  # |                                                             |
  # |   !!! BELOW IS THE ORIGINAL BEHAVIOUR ... DON'T TOUCH !!!   |
  # |                                                             |
  # +-------------------------------------------------------------+

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /users' do
      it(:authenticated)   { should auth status: 200, empty: false }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end

    describe 'GET /users/permissions' do
      it(:authenticated)   { should auth status: 406} # no v1 serializer for permissions
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end

    describe 'GET /users/%{user.id}' do
      it(:authenticated)   { should auth status: 200, empty: false }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end

    describe 'GET /users/0' do
      it(:authenticated)   { should auth status: 302 } # redirects to /repos/users/0
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end
  end
end
