require 'spec_helper'

describe 'Workers' do
  let!(:workers) { [Worker.create(full_name: 'one'), Worker.create(full_name: 'two')] }
  let(:headers)  { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.1+json' } }

  it 'GET /workers' do
    Worker.stubs(all: @workers)
    response = get '/workers', {}, headers
    response.should deliver_json_for(Worker.all, version: 'v1', type: 'workers')
  end
end

