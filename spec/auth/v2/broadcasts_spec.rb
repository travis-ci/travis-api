describe 'v2 broadcasts', auth_helpers: true, api_version: :v2, set_app: true do
  let(:user) { FactoryBot.create(:user) }

  before { Broadcast.create!(recipient: user, recipient_type: 'User') }

  describe 'in public mode', mode: :public do
    describe 'GET /broadcasts' do
      it(:authenticated)   { should auth status: 200, type: :json, empty: false }
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
      it(:authenticated)   { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end
  end

  describe 'in org mode', mode: :org do
    describe 'GET /broadcasts' do
      it(:authenticated)   { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end
  end
end
