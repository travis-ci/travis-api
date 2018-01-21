describe 'Auth accounts', auth_helpers: true, site: :org, api_version: :v1, set_app: true do
  let(:user) { FactoryBot.create(:user) }

  before { Broadcast.create!(recipient: user) }

  describe 'in org mode', mode: :org do
    describe 'GET /accounts' do
      it(:authenticated)   { should auth status: 406 } # no v1 serializer for accounts
      it(:invalid_token)   { should auth status: 403 }
      it(:unauthenticated) { should auth status: 401 }
    end
  end
end
