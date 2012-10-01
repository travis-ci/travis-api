require 'spec_helper'

describe 'Workers' do
  before(:each) do
    Time.stubs(:now).returns(Time.utc(2011, 11, 11, 11, 11, 11))
    @workers = [
      Factory(:worker, :name => 'worker-1', :state => :working),
      Factory(:worker, :name => 'worker-2', :state => :errored)
    ]
  end

  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.1+json' } }

  attr_reader :workers

  it 'GET /workers' do
    response = get '/workers', {}, headers
    response.should deliver_json_for(Worker.order(:host, :name), version: 'v1')
  end
end

