describe 'v1 broadcasts', auth_helpers: true, api_version: :v1, set_app: true do
  let(:user) { FactoryBot.create(:user) }

  before { Broadcast.create!(recipient: user) }

  describe 'in public mode', mode: :public do
    describe 'GET /broadcasts' do
      it(:authenticated)   { should auth status: 406 } # no v1 serializer for broadcasts
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end
  end

  # +----------------------------------------------------+
  # |                                                    |
  # |   !!! THE ORIGINAL BEHAVIOUR ... DON'T TOUCH !!!   |
  # |                                                    |
  # +----------------------------------------------------+

  describe 'in private mode', mode: :private do
    describe 'GET /broadcasts' do
      it(:authenticated)   { should auth status: 406 } # no v1 serializer for broadcasts
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end
  end

  describe 'in org mode', mode: :org do
    describe 'GET /broadcasts' do
      it(:authenticated)   { should auth status: 406 } # no v1 serializer for broadcasts
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end
  end
end
