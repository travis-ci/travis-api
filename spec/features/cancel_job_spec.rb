require 'rails_helper'

RSpec.feature 'Cancel a Job', js: true, type: :feature do
  let!(:organization) { create(:organization) }
  let!(:repository)   { create(:repository, owner: organization) }
  let!(:build)        { create(:started_build, repository: repository) }
  let!(:job)          { create(:started_job, repository: repository, build: build, config: {}) }


  scenario 'User cancels a job' do
    allow_any_instance_of(Services::Job::GetLog).to receive(:call)

    visit "/jobs/#{job.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/job/#{job.id}/cancel").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: '', headers: {})

    find_button('Cancel').trigger('click')

    expect(page).to have_text('Job travis-pro/travis-admin#123.4 successfully canceled.')
  end

  scenario 'User cancels a job via jobs tab in organization view' do

    visit "/organizations/#{organization.id}/jobs"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/job/#{job.id}/cancel").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: '', headers: {})

    find_button('Cancel').trigger('click')

    expect(page).to have_text('Job travis-pro/travis-admin#123.4 successfully canceled.')
    expect(page).to have_button('Canceled', disabled: true)
  end
end
