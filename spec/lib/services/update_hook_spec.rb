describe Travis::Services::UpdateHook do
  include Travis::Testing::Stubs

  let(:service) { described_class.new(user, params) }
  let(:params)  { { id: repo.id, active: true } }

  before :each do
    allow(repo).to receive(:update_column)
    allow(service).to receive(:run_service)
    allow(user).to receive(:service_hook).and_return(repo)
  end

  it 'finds the repo by the given params' do
    expect(user).to receive(:service_hook).with({id: repo.id}).and_return(repo)
    service.run
  end

  it 'sets the given :active param to the hook' do
    expect(service).to receive(:run_service).with(:github_set_hook, instance_of(Hash))
    service.run
  end

  describe 'sets the repo to the active param' do
    it 'given true' do
      service.params.update(active: true)
      expect(repo).to receive(:update_column).with(:active, true)
      service.run
    end

    it 'given false' do
      service.params.update(active: false)
      expect(repo).to receive(:update_column).with(:active, false)
      service.run
    end

    it 'given "true"' do
      service.params.update(active: 'true')
      expect(repo).to receive(:update_column).with(:active, true)
      service.run
    end

    it 'given "false"' do
      service.params.update(active: 'false')
      expect(repo).to receive(:update_column).with(:active, false)
      service.run
    end
  end

  it 'syncs the repo when activated' do
    service.params.update(active: true)
    expect(Sidekiq::Client).to receive(:push).with(
      'queue' => 'sync',
      'class' => 'Travis::GithubSync::Worker',
      'args'  => [:sync_repo, repo_id: 1, user_id: user.id].map! {|arg| arg.to_json}
    )
    service.run
  end

  it 'does not sync the repo when deactivated' do
    service.params.update(active: false)
    expect(Sidekiq::Client).not_to receive(:push)
    service.run
  end
end

describe Travis::Services::UpdateHook::Instrument do
  include Travis::Testing::Stubs

  let(:service)   { Travis::Services::UpdateHook.new(user, params) }
  let(:params)    { { id: repository.id, active: 'true' } }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:event)     { publisher.events.last }

  before :each do
    Travis::Notification.publishers.replace([publisher])
    allow(service).to receive(:run_service)
    allow(user).to receive(:service_hook).and_return(repo)
    allow(repo).to receive(:update_column).and_return(true)
  end

  it 'publishes a event' do
    service.run
    expect(event).to publish_instrumentation_event(
      event: 'travis.services.update_hook.run:completed',
      message: 'Travis::Services::UpdateHook#run:completed for svenfuchs/minimal active=true (svenfuchs)',
      result: true
    )
  end
end

