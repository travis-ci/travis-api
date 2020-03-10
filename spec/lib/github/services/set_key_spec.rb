describe Travis::Github::Services::SetKey do
  include Travis::Testing::Stubs

  let(:keys_path) { 'repos/travis-ci/travis-core/keys' }
  let(:key_path)  { "#{keys_path}/1" }
  let(:keys)      { [{ 'id' => 1, 'key' => SSL_KEYS[:public_base64], '_links' => { 'self' => { 'href' => key_path } } }] }
  let(:key)       { SslKey.new(SSL_KEYS.slice(:private_key, :public_key)) }
  let(:owner)     { User.new(login: 'travis-ci') }
  let(:repo)      { Repository.new(owner_name: 'travis-ci', name: 'travis-core', key: key, owner: owner) }

  let(:params)    { { id: repo.id } }
  let(:service)   { described_class.new(user, params) }

  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:event)     { publisher.events.last }

  before :each do
    allow(GH).to receive(:[]).and_return([])
    allow(GH).to receive(:post)
    allow(GH).to receive(:delete)
    Travis::Notification.publishers.replace([publisher])
    allow_any_instance_of(Travis::Services::FindRepo).to receive(:run).and_return(repo)
  end

  it 'authenticates with the current user' do
    expect(Travis::Github).to receive(:authenticated).with(user).at_least(:once).and_return([])
    service.run
  end

  describe 'given force: false' do
    before :each do
      params.update force: false
    end

    it 'does not try to delete an existing key on github' do
      allow(GH).to receive(:[]).with('repos/travis-ci/travis-core/keys').and_return(keys)
      expect(GH).not_to receive(:delete)
      service.run
    end

    it 'sets the encoded public repository key to github if github does not have it' do
      allow(GH).to receive(:[]).with(keys_path).and_return([])
      expect(GH).to receive(:post).with(keys_path, title: 'travis-ci.org', key: SSL_KEYS[:public_base64], read_only: true)
      service.run
    end

    it 'does not set anything to github if github already has the encoded public repository key' do
      allow(GH).to receive(:[]).with('repos/travis-ci/travis-core/keys').and_return(keys)
      expect(GH).not_to receive(:post)
      service.run
    end
  end

  describe 'given force: true' do
    before :each do
      params.update force: true
    end

    it 'does not try to delete a key on github when no one exists' do
      allow(GH).to receive(:[]).with('repos/travis-ci/travis-core/keys').and_return([])
      expect(GH).not_to receive(:delete)
      service.run
    end

    it 'deletes an existing key on github' do
      allow(GH).to receive(:[]).with('repos/travis-ci/travis-core/keys').and_return(keys)
      expect(GH).to receive(:delete).with(key_path)
      service.run
    end

    it 'sets the encoded public repository key to github' do
      allow(GH).to receive(:[]).with('repos/travis-ci/travis-core/keys').and_return(keys)
      expect(GH).to receive(:post).with(keys_path, title: 'travis-ci.org', key: SSL_KEYS[:public_base64], read_only: true)
      service.run
    end
  end

  it 'publishes an event' do
    service.run
    expect(event).to publish_instrumentation_event(
      event: 'travis.github.services.set_key.run:completed',
      message: 'Travis::Github::Services::SetKey#run:completed for travis-ci/travis-core',
      result: nil
    )
  end
end
