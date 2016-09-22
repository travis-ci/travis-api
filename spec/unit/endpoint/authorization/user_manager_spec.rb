describe Travis::Api::App::Endpoint::Authorization::UserManager do
  let(:manager) { described_class.new(data, 'abc123') }

  before do
    Travis::Features.enable_for_all(:education_data_sync)
    Travis::Github::Oauth.stubs(:update_scopes) # TODO test that scopes are being updated
  end

  describe '#info' do
    let(:data) {
      {
        name: 'Piotr Sarnacki', login: 'drogus', gravatar_id: '123', id: 456, foo: 'bar'
      }.stringify_keys
    }

    before { manager.stubs(:education).returns(false) }

    it 'gets data from github payload' do
      manager.info.should == {
        name: 'Piotr Sarnacki', login: 'drogus', gravatar_id: '123', github_id: 456, education: false
      }.stringify_keys
    end

    it 'allows to overwrite existing keys' do
      manager.info({login: 'piotr.sarnacki', bar: 'baz'}.stringify_keys).should == {
        name: 'Piotr Sarnacki', login: 'piotr.sarnacki', gravatar_id: '123',
        github_id: 456, bar: 'baz', education: false
      }.stringify_keys
    end
  end

  describe '#fetch' do
    let(:data) {
       { login: 'drogus', id: 456 }.stringify_keys
     }

    it 'drops the token when drop_token is set to true' do
      user = stub('user', login: 'drogus', github_id: 456, previous_changes: {})
      User.expects(:find_by_github_id).with(456).returns(user)

      manager = described_class.new(data, 'abc123', true)
      manager.stubs(:education).returns(false)

      attributes = { login: 'drogus', github_id: 456, education: false }.stringify_keys

      user.expects(:update_attributes).with(attributes)

      manager.fetch.should == user
    end

    context 'with existing user' do
      let!(:user) { FactoryGirl.create(:user, login: 'drogus', github_id: 456, github_oauth_token: token) }
      let(:token) { nil }

      before do
        manager.stubs(:education).returns(false)
      end

      it 'updates user data' do
        attributes = { login: 'drogus', github_id: 456, github_oauth_token: 'abc123', education: false }.stringify_keys
        User.any_instance.expects(:update_attributes).with(attributes)
        manager.fetch.should == user
      end

      describe 'the oauth token has not changed' do
        let(:token) { 'abc123' }

        it 'syncs the user' do
          Travis.expects(:run_service).with(:sync_user, user).never
          manager.fetch
        end
      end

      describe 'the oauth token has changed' do
        let(:token) { 'xyz890' }

        it 'syncs the user' do
          Travis.expects(:run_service).with(:sync_user, user)
          manager.fetch
        end
      end
    end

    context 'without existing user' do
      let(:user)  { User.create(id: 1, login: 'drogus', github_id: 456) }
      let(:attrs) { { login: 'drogus', github_id: 456, github_oauth_token: 'abc123', education: false }.stringify_keys }

      before do
        manager.stubs(:education).returns(false)
        User.stubs(:create!).with(attrs).returns(user)
      end

      it 'creates new user' do
        User.expects(:create!).with(attrs).returns(user)
        manager.fetch.should == user
      end

      it 'syncs the user' do
        Travis.expects(:run_service).with(:sync_user, user)
        manager.fetch
      end
    end
  end

  describe '#education' do
    let(:data) { {} }
    it 'runs students check with token' do
      education = stub(:education)
      education.expects(:student?).returns(true)
      Travis::Github::Education.expects(:new).with('abc123').returns(education)

      manager.education.should be_truthy
    end
  end
end
