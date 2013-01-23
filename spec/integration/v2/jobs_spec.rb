require 'spec_helper'

describe 'Jobs' do
  let!(:jobs) {[
    FactoryGirl.create(:test, :number => '3.1', :queue => 'builds.common'),
    FactoryGirl.create(:test, :number => '3.2', :queue => 'builds.common')
  ]}
  let(:job) { jobs.first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  it '/jobs?queue=builds.common' do
    response = get '/jobs', { queue: 'builds.common' }, headers
    response.should deliver_json_for(Job.queued('builds.common'), version: 'v2')
  end

  it '/jobs/:id' do
    response = get "/jobs/#{job.id}", {}, headers
    response.should deliver_json_for(job, version: 'v2')
  end

  it '/jobs/:id' do
    job.log.update_attributes!(content: 'the log')
    response = get "/jobs/#{job.id}/log.txt", {}, headers
    response.should deliver_as_txt('the log', version: 'v2')
  end
end
