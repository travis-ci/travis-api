require 'rails_helper'

RSpec.feature 'Cancel a Job', :js => true, :type => :feature do
  let!(:organization) { create(:organization) }
  let!(:repository) { create(:repository, owner: organization) }
  let!(:build) { create(:build, repository: repository, number: 1)}
  let!(:job) { create(:job, repository: repository, build: build, started_at: '2016-06-29 11:06:01', finished_at: nil, state: 'started', config: {}) }

  scenario 'User cancels a job' do
    allow_any_instance_of(Services::Job::Log).to receive(:call)

    visit "/jobs/#{job.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/job/#{job.id}/cancel").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => '', :headers => {})

    find_button('Cancel').trigger('click')

    expect(page).to have_text('Job travis-pro/travis-admin#123 successfully canceled.')
  end

  scenario 'User cancels a job via jobs tab in organization view' do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/organizations/#{organization.id}#jobs"

    # Capybara needs this extra click
    click_on('Jobs')

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/job/#{job.id}/cancel").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => '', :headers => {})

    find_button('Cancel').trigger('click')

    expect(page).to have_text('Job travis-pro/travis-admin#123 successfully canceled.')
    expect(page).to have_button('Canceled', disabled: true)
  end
end
