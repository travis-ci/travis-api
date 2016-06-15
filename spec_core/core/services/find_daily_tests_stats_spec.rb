require 'spec_helper'
require 'travis/testing/scenario'

describe Travis::Services::FindDailyTestsStats do
  include Support::ActiveRecord

  let(:service) { described_class.new(stub('user'), {}) }

  before { Scenario.default }

  it 'should return the jobs per day' do
    stats = service.run
    expect(stats.size).to eq(1)
    stats.first['date'].should == Job.first.created_at.to_date.to_s(:date)
    stats.first['count'].to_i.should == 13
  end
end
