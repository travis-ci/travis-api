describe Travis::Github::Services::SetKey do
  include Travis::Testing::Stubs

  let(:keys_path) { 'repos/travis-ci/travis-core/keys' }
  let(:key_path)  { "#{keys_path}/1" }
  let(:keys)      { [{ 'id' => 1, 'key' => SSL_KEYS[:public_base64], '_links' => { 'self' => { 'href' => key_path } } }] }
  let(:key)       { SslKey.new(SSL_KEYS.slice(:private_key, :public_key)) }
  let(:repo)      { Repository.new(owner_name: 'travis-ci', name: 'travis-core', key: key) }

  let(:params)    { { id: repo.id } }
  let(:service)   { described_class.new(user, params) }

  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:event)     { publisher.events.last }

  before :each do
    GH.stubs(:[]).returns([])
    GH.stubs(:post)
    GH.stubs(:delete)
    Travis::Notification.publishers.replace([publisher])
    Travis::Services::FindRepo.any_instance.stubs(:run).returns(repo)
  end

  it 'authenticates with the current user' do
    Travis::Github.expects(:authenticated).with(user).at_least_once.returns([])
    service.run
  end

  describe 'given force: false' do
    before :each do
      params.update force: false
    end

    it 'does not try to delete an existing key on github' do
      GH.stubs(:[]).with('repos/travis-ci/travis-core/keys').returns(keys)
      GH.expects(:delete).never
      service.run
    end

    it 'sets the encoded public repository key to github if github does not have it' do
      GH.stubs(:[]).with(keys_path).returns([])
      GH.expects(:post).with(keys_path, title: 'travis-ci.org', key: SSL_KEYS[:public_base64], read_only: true)
      service.run
    end

    it 'does not set anything to github if github already has the encoded public repository key' do
      GH.stubs(:[]).with('repos/travis-ci/travis-core/keys').returns(keys)
      GH.expects(:post).never
      service.run
    end
  end

  describe 'given force: true' do
    before :each do
      params.update force: true
    end

    it 'does not try to delete a key on github when no one exists' do
      GH.stubs(:[]).with('repos/travis-ci/travis-core/keys').returns([])
      GH.expects(:delete).never
      service.run
    end

    it 'deletes an existing key on github' do
      GH.stubs(:[]).with('repos/travis-ci/travis-core/keys').returns(keys)
      GH.expects(:delete).with(key_path)
      service.run
    end

    it 'sets the encoded public repository key to github' do
      GH.stubs(:[]).with('repos/travis-ci/travis-core/keys').returns(keys)
      GH.expects(:post).with(keys_path, title: 'travis-ci.org', key: SSL_KEYS[:public_base64], read_only: true)
      service.run
    end
  end

  it 'publishes an event' do
    service.run
    event.should publish_instrumentation_event(
      event: 'travis.github.services.set_key.run:completed',
      message: 'Travis::Github::Services::SetKey#run:completed for travis-ci/travis-core',
      result: nil
    )
  end
end
