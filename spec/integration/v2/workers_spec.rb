require 'spec_helper'

describe 'Workers' do
  before(:each) do
    Time.stubs(:now).returns(Time.utc(2011, 11, 11, 11, 11, 11))
    @workers = [
      Worker.new('1', full_name: 'ruby1:ruby1.travis-ci.org'),
      Worker.new('2', full_name: 'ruby2:ruby1.travis-ci.org')
    ]
  end

  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  attr_reader :workers

  it 'GET /workers' do
    Worker.stubs(all: @workers)
    response = get '/workers', {}, headers
    response.should deliver_json_for(@workers, version: 'v2', type: 'workers')
  end
end

