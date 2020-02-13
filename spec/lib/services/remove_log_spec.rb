describe Travis::Services::RemoveLog do
  let(:repo)    { FactoryBot.create(:repository) }
  let(:job)     { FactoryBot.create(:test, repository: repo, state: :created) }
  let(:user)    { FactoryBot.create(:user) }
  let(:service) { described_class.new(user, params) }
  let(:params)  { { id: job.id, reason: 'Because reason!'} }

  context 'when job is not finished' do
    before :each do
      allow(job).to receive(:finished?).and_return false
      allow(user).to receive(:permission?).with(:push, anything).and_return true
      stub_request(
        :any, /#{URI(Travis.config.logs_api.url).hostname}/
      ).to_return(status: 200, body: JSON.dump(content: '', job_id: job.id))
    end

    it 'raises JobUnfinished error' do
      expect {
        service.run
      }.to raise_error Travis::JobUnfinished
    end
  end

  context 'when user does not have push permissions' do
    before :each do
      allow(user).to receive(:permission?).with(:push, anything).and_return false
      stub_request(
        :any, /#{URI(Travis.config.logs_api.url).hostname}/
      ).to_return(status: 200, body: JSON.dump(content: '', job_id: job.id))
    end

    it 'raises AuthorizationDenied' do
      expect {
        service.run
      }.to raise_error Travis::AuthorizationDenied
    end
  end

  context 'when a job is found' do
    before do
      find_by_id = double
      allow(find_by_id).to receive(:find_by_id).and_return job
      allow(job).to receive(:finished?).and_return true
      allow(service).to receive(:scope).and_return find_by_id
      allow(user).to receive(:permission?).with(:push, anything).and_return true
      stub_request(
        :get,
        "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id&source=api"
      ).to_return(
        status: 200,
        body: JSON.dump(
          content: 'wow log wow',
          job_id: job.id
        )
      )
      stub_request(
        :put,
        "#{Travis.config.logs_api.url}/logs/#{job.id}?removed_by=#{user.id}&source=api"
      ).with(
        body: /Log removed by #{user.name}/
      ).to_return(
        status: 200,
        body: JSON.dump(
          content: "Log removed by #{user.name} at #{Time.now.utc} Because reason!",
          removed_at: Time.now.utc.to_s,
          removed_by_id: user.id,
          job_id: job.id
        )
      )
    end

    it 'runs successfully' do
      result = service.run
      expect(result.removed_by).to eq user
      expect(result.removed_at).to be_truthy
      expect(result).to be_truthy
    end

    it 'updates logs with desired information' do
      service.run
      expect(service.log.content).to be =~ Regexp.new(user.name)
      expect(service.log.content).to be =~ Regexp.new(params[:reason])
    end

    context 'when log is already removed' do
      it 'raises LogAlreadyRemoved error' do
        service.run
        expect {
          service.run
        }.to raise_error Travis::LogAlreadyRemoved
      end
    end
  end

  context 'when a job is not found' do
    before :each do
      find_by_id = double
      allow(find_by_id).to receive(:find_by_id).and_raise(ActiveRecord::SubclassNotFound)
      allow(service).to receive(:scope).and_return(find_by_id)
    end

    it 'raises ActiveRecord::RecordNotFound exception' do
      expect { service.run }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

end

describe Travis::Services::RemoveLog::Instrument do
  let(:service)   { Travis::Services::RemoveLog.new(user, params) }
  let(:repo)      { FactoryBot.create(:repository) }
  let(:user)      { FactoryBot.create(:user) }
  let(:job)       { FactoryBot.create(:test, repository: repo, state: :passed) }
  let(:params)    { { id: job.id, reason: 'Because Science!' } }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:event)     { publisher.events.last }

  before :each do
    Travis::Notification.publishers.replace([publisher])
    allow(service).to receive(:run_service)
    allow(user).to receive(:permission?).with(:push, anything).and_return true
    stub_request(
      :any, /#{URI(Travis.config.logs_api.url).hostname}/
    ).to_return(status: 200, body: JSON.dump(content: '', job_id: job.id))
  end

  it 'publishes a event' do
    service.run
    expect(event).to publish_instrumentation_event(
      event: 'travis.services.remove_log.run:completed',
      message: "Travis::Services::RemoveLog#run:completed for <Job id=#{job.id}> (svenfuchs)",
    )
  end
end
