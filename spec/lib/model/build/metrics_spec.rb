class BuildMetricsMock
  include do
    attr_accessor :state, :request

    def initialize(request)
      @request = request
    end

    def start(data = {})
      self.state = :started
    end

    def started_at
      Time.now
    end

  end

  include Build::Metrics
end

describe Build::Metrics do
  let(:request) { double('request', created_at: Time.now - 60) }
  let(:build) { BuildMetricsMock.new(request) }
  let(:timer) { double('meter', update: nil) }

  before :each do
    allow(Metriks).to receive(:timer).and_return(timer)
  end

  it 'measures on "travis.builds.start.delay"' do
    expect(Metriks).to receive(:timer).with('travis.builds.start.delay').and_return(timer)
    build.start(started_at: Time.now)
  end

  xit 'measures the time it takes from creating the request until starting the build' do
    expect(timer).to receive(:update).with(60)
    build.start(started_at: Time.now)
  end
end
