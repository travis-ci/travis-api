describe Travis::Github::Services::SetKey do
  include Travis::Testing::Stubs
  let(:keys_path) { 'repos/travis-ci/travis-core/keys' }
  let(:key_path)  { "#{keys_path}/1" }
  let(:keys)      { [{ 'id' => 1, 'key' => SSL_KEYS[:public_base64], '_links' => { 'self' => { 'href' => key_path } } }] }
  let(:key)       { SslKey.new(SSL_KEYS.slice(:private_key, :public_key)) }
  let(:owner)     { User.new(id: 1, login: 'travis-ci') }
  let(:repo)      { Repository.new(id: 1, owner_name: 'travis-ci', name: 'travis-core', key: key, owner: owner) }
  let(:params)    { { id: repo.id } }
  let(:service)   { described_class.new(user, params) }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:event)     { publisher.events.last }
  let!(:keys_request) do
    WebMock.stub_request(:get, "http://vcsfake.travis-ci.com/repos/#{repo.id}/keys?user_id=#{owner.id}")
      .to_return(
        status: 200,
        body: JSON.dump(keys)
      )
  end
  let!(:delete_request) do
    WebMock.stub_request(:delete, "http://vcsfake.travis-ci.com/repos/#{repo.id}/keys/1?user_id=#{owner.id}")
      .to_return(
        status: 200,
        body: nil,
      )
  end
  let!(:create_request) do
    WebMock.stub_request(:post, "http://vcsfake.travis-ci.com/repos/#{repo.id}/keys?user_id=#{owner.id}&read_only=true")
      .to_return(
        status: 201,
        body: nil,
      )
  end
  before do
    Travis.config.vcs.url = 'http://vcsfake.travis-ci.com'
    Travis.config.vcs.token = 'vcs-token'
    Travis::Notification.publishers.replace([publisher])
    allow_any_instance_of(Travis::Services::FindRepo).to receive(:run).and_return(repo)
  end
  describe 'given force: false' do
    before do
      params[:force] = false
    end
    it 'does not try to delete an existing key on github' do
      service.run
      expect(delete_request).not_to have_been_made
      expect(create_request).not_to have_been_made
    end
    context 'when there are no keys' do
      let(:keys) { [] }
      it 'sets the encoded public repository key to github' do
        service.run
        expect(create_request).to have_been_made
      end
    end
  end
  describe 'given force: true' do
    before do
      params[:force] = true
    end
    context 'when no keys exist' do
      let(:keys) { [] }
      it 'does not try to delete a key on github' do
        service.run
        expect(delete_request).not_to have_been_made
      end
    end
    it 'deletes an existing key on github' do
      service.run
      expect(delete_request).to have_been_made
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
