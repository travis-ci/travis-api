describe Travis::Api::App::Services::ScheduleRequest::Throttle do
  let(:repo) { Factory(:repository) }
  subject    { described_class.new(repo.slug) }

  it 'does not throttle by default' do
    expect(subject.throttled?).to eq false
  end

  it 'throttles with more then N requests for the same repo in the last hour' do
    10.times { Request.create!(repository: repo, event_type: 'api', result: 'accepted') }
    expect(subject.throttled?).to eq true
  end

  it 'does not throttle with more then N requests for other repos in the last hour' do
    10.times { Request.create!(repository: Factory(:repository), event_type: 'api', result: 'accepted') }
    expect(subject.throttled?).to eq false
  end

  it 'throttles with more then 20 requests for the /coupons endpoint in the last day' do
    21.times { get('/coupons/ABC') }
    expect(subject.throttled?).to eq true
  end

end
