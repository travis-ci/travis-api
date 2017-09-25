require 'rails_helper'

RSpec.feature 'Restart a Job', js: true, type: :feature do
  let!(:organization) { create(:organization) }
  let!(:repository)   { create(:repository, owner: organization) }
  let!(:build)        { create(:failed_build, repository: repository)}
  let!(:job)          { create(:failed_job, repository: repository, build: build, config: {}) }

  scenario 'User restarts a job' do
    allow_any_instance_of(Services::Job::GetLog).to receive(:call)

    visit "/jobs/#{job.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/job/#{job.id}/restart").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: '', headers: {})

    find_button('Restart').trigger('click')

    expect(page).to have_text('Job travis-pro/travis-admin#123.4 successfully restarted.')
  end

  scenario 'User restarts a job via jobs tab in organization view' do
    visit "/organizations/#{organization.id}#jobs"

    # Capybara needs this extra click
    click_on('Jobs')

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/job/#{job.id}/restart").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: '', headers: {})

    find_button('Restart').trigger('click')

    expect(page).to have_text('Job travis-pro/travis-admin#123.4 successfully restarted.')
    expect(page).to have_button('Restarted', disabled: true)
  end
end
