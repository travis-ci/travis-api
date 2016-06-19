describe Travis::Api::App::Endpoint::Authorization::UserManager do
  let(:manager) { described_class.new(data, 'abc123') }

  before do
    Travis::Features.enable_for_all(:education_data_sync)
    Travis::Github::Oauth.stubs(:track_scopes) # TODO test that scopes are being updated
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
      user = stub('user', login: 'drogus', github_id: 456)
      User.expects(:find_by_github_id).with(456).returns(user)

      manager = described_class.new(data, 'abc123', true)
      manager.stubs(:education).returns(false)

      attributes = { login: 'drogus', github_id: 456, education: false }.stringify_keys

      user.expects(:update_attributes).with(attributes)

      manager.fetch.should == user
    end

    context 'with existing user' do
      it 'updates user data' do
        user = stub('user', login: 'drogus', github_id: 456)
        User.expects(:find_by_github_id).with(456).returns(user)
        attributes = { login: 'drogus', github_id: 456, github_oauth_token: 'abc123', education: false }.stringify_keys
        user.expects(:update_attributes).with(attributes)
        manager.stubs(:education).returns(false)

        manager.fetch.should == user
      end
    end

    context 'without existing user' do
      it 'creates new user' do
        user = stub('user', login: 'drogus', github_id: 456)
        User.expects(:find_by_github_id).with(456).returns(nil)
        attributes = { login: 'drogus', github_id: 456, github_oauth_token: 'abc123', education: false }.stringify_keys
        User.expects(:create!).with(attributes).returns(user)
        manager.stubs(:education).returns(false)

        manager.fetch.should == user
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
