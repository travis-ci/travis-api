describe Travis::Api::App::Endpoint::Authorization::UserManager, billing_spec_helper: true do
  let(:manager) { described_class.new(data, 'abc123') }

  before do
    Travis::Features.enable_for_all(:education_data_sync)
    allow(Travis::Github::Oauth).to receive(:update_scopes) # TODO test that scopes are being updated
  end

  describe '#info' do
    let(:data) {
      {
        name: 'Piotr Sarnacki', login: 'drogus', gravatar_id: '123', id: 456, foo: 'bar'
      }.stringify_keys
    }

    before { allow(manager).to receive(:education).and_return(false) }

    it 'gets data from github payload' do
      expect(manager.info).to eq({
        name: 'Piotr Sarnacki', login: 'drogus', gravatar_id: '123', github_id: 456, education: false, vcs_id: 456
      }.stringify_keys)
    end

    it 'allows to overwrite existing keys' do
      expect(manager.info({login: 'piotr.sarnacki', bar: 'baz'}.stringify_keys)).to eq({
        name: 'Piotr Sarnacki', login: 'piotr.sarnacki', gravatar_id: '123',
        github_id: 456, bar: 'baz', education: false, vcs_id: 456
      }.stringify_keys)
    end
  end

  describe '#fetch' do
    let(:data) {
       { login: 'drogus', id: 456 }.stringify_keys
     }

    it 'drops the token when drop_token is set to true' do
      user = double('user', login: 'drogus', github_id: 456, previous_changes: {}, recently_signed_up?: false, tokens: [double('token')])
      expect(User).to receive(:find_by_github_id).with(456).and_return(user)

      manager = described_class.new(data, 'abc123', true)
      allow(manager).to receive(:education).and_return(false)

      attributes = { login: 'drogus', github_id: 456, education: false, vcs_id: 456 }.stringify_keys

      expect(user).to receive(:update).with(attributes)

      expect(manager.fetch).to eq(user)
    end

    context 'with existing user' do
      let!(:user) { FactoryBot.create(:user, login: 'drogus', github_id: 456, github_oauth_token: token) }
      let(:token) { nil }
      let(:billing_url) { 'http://billingfake.travis-ci.com' }
      let(:billing_auth_key) { 'secret' }

      before do
        allow(manager).to receive(:education).and_return(false)
        Travis.config.billing.url = billing_url
        Travis.config.billing.auth_key = billing_auth_key
        stubbed_request = stub_billing_request(:post, "/v2/initial_subscription", auth_key: billing_auth_key, user_id: user.id)
                          .to_return(status: 201, body: JSON.dump(billing_v2_subscription_response_body('id' => 456, 'owner' => { 'type' => 'User', 'id' => user.id })))
      end

      context 'without any User#tokens record' do
        before do
          user.tokens.destroy_all
        end

        it 'creates a User#tokens record' do
          expect_any_instance_of(User).to receive(:create_a_token)
          expect_any_instance_of(User).to receive(:tokens).and_return([])
          expect(manager.fetch).to eq(user)
        end
      end

      it 'updates user data' do
        attributes = { login: 'drogus', github_id: 456, github_oauth_token: 'abc123', education: false, vcs_id: 456 }.stringify_keys
        expect_any_instance_of(User).to receive(:update).with(attributes)
        expect(manager.fetch).to eq(user)
      end
    end

    context 'without existing user' do
      let(:user)  { User.create(login: 'drogus', github_id: 456, vcs_id: 456) }
      let(:attrs) { { login: 'drogus', github_id: 456, github_oauth_token: 'abc123', education: false, vcs_id: 456 }.stringify_keys }

      before do
        allow(manager).to receive(:education).and_return(false)
        allow(User).to receive(:create!).with(attrs).and_return(user)
      end

      it 'creates new user' do
        expect(User).to receive(:create!).with(attrs).and_return(user)
        expect(manager.fetch).to eq(user)
      end
    end
  end

  describe '#education' do
    let(:data) { {} }
    it 'runs students check with token' do
      education = double(:education => nil)
      expect(education).to receive(:student?).and_return(true)
      expect(Travis::Github::Education).to receive(:new).with('abc123').and_return(education)

      expect(manager.education).to be_truthy
    end
  end
end
