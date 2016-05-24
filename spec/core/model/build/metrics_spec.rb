require 'spec_helper'

class BuildMetricsMock
  include do
    attr_accessor :state

    def start(data = {})
      self.state = :started
    end

    def started_at
      Time.now
    end

    def request
      stub('request', created_at: Time.now - 60)
    end
  end

  include Build::Metrics
end

describe Build::Metrics do
  let(:build) { BuildMetricsMock.new }
  let(:timer) { stub('meter', :update) }

  before :each do
    Metriks.stubs(:timer).returns(timer)
  end

  it 'measures on "travis.builds.start.delay"' do
    Metriks.expects(:timer).with('travis.builds.start.delay').returns(timer)
    build.start(started_at: Time.now)
  end

  it 'measures the time it takes from creating the request until starting the build' do
    timer.expects(:update).with(60)
    build.start(started_at: Time.now)
  end
end
