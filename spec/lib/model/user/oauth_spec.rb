describe User::Oauth do
  let(:user)    { FactoryBot.create(:user, :github_oauth_token => 'token') }
  let(:payload) { GITHUB_PAYLOADS[:oauth] }

  describe 'find_or_create_by' do
    def call(payload)
      User::Oauth.find_or_create_by(payload)
    end

    it 'marks users as recently_signed_up' do
      expect(call(payload)).to be_recently_signed_up
    end

    it 'does not mark existing users as recently_signed_up' do
      call(payload)
      expect(call(payload)).not_to be_recently_signed_up
    end

    it 'updates changed attributes' do
      expect(call(payload).attributes.slice(*GITHUB_OAUTH_DATA.keys)).to eq(GITHUB_OAUTH_DATA)
    end
  end

  describe 'attributes_from' do
    it 'returns required data' do
      expect(User::Oauth.attributes_from(payload)).to eq(GITHUB_OAUTH_DATA)
    end
  end
end
