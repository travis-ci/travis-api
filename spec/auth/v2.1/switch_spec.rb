describe 'v2.1 switch', auth_helpers: true, api_version: :'v2.1', set_app: true do
  let(:user) { FactoryBot.create(:user) }
  let(:repo) { Repository.first }

  describe 'by default' do
    describe 'GET /repos/%{repo.id}' do
      it(:with_permission) { should auth status: 200, type: :json, empty: false }
    end
  end

  describe 'disabled' do
    env DISABLE_V2_1: true

    describe 'GET /repos/%{repo.id}' do
      it(:with_permission) { should auth status: 406 }
    end
  end
end
