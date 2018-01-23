describe 'Auth broadcasts', auth_helpers: true, api_version: :v2, set_app: true do
  let(:user) { FactoryBot.create(:user) }

  before { Broadcast.create!(recipient: user) }

  # +----------------------------------------------------+
  # |                                                    |
  # |   !!! THE ORIGINAL BEHAVIOUR ... DON'T TOUCH !!!   |
  # |                                                    |
  # +----------------------------------------------------+

  describe 'in private mode', mode: :private do
    describe 'GET /broadcasts' do
      it(:authenticated)   { should auth status: 200, empty: false }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end
  end

  describe 'in org mode', mode: :org do
    describe 'GET /broadcasts' do
      it(:authenticated)   { should auth status: 200, empty: false }
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end
  end
end
