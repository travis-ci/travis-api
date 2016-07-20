require 'rails_helper'

RSpec.feature "Cancel a Job", :js => true, :type => :feature do
  let!(:job) { create(:job, started_at: '2016-06-29 11:06:01', finished_at: nil, config: {}) }

  scenario "User cancels a job" do
    visit "/job/#{job.id}"

    WebMock.stub_request(:post, "https://api.travis-ci.com/job/#{job.id}/cancel").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => '', :headers => {})

    click_button('Cancel')

    expect(page).to have_text('Job successfully canceled.')
    expect(page).to have_text('canceled', count: 2)
  end
end