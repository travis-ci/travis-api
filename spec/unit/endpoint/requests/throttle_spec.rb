describe Travis::Api::App::Services::ScheduleRequest::Throttle do
  let(:repo) { FactoryBot.create(:repository) }
  subject    { described_class.new(repo.slug) }

  it 'does not throttle by default' do
    expect(subject.throttled?).to eq false
  end

  it 'throttles with more then N requests for the same repo in the last hour' do
    10.times { Request.create!(repository: repo, event_type: 'api', result: 'accepted') }
    expect(subject.throttled?).to eq true
  end

  it 'does not throttle with more then N requests for other repos in the last hour' do
    10.times { Request.create!(repository: FactoryBot.create(:repository), event_type: 'api', result: 'accepted') }
    expect(subject.throttled?).to eq false
  end
end
