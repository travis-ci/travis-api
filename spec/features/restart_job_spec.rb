require 'rails_helper'

RSpec.feature 'Restart a Job', :js => true, :type => :feature do
  let!(:job) { create(:job, started_at: '2016-06-29 11:06:01', finished_at: '2016-06-29 11:09:09', state: 'failed', config: {}) }

  scenario 'User restarts a job' do
    visit "/job/#{job.id}"

    WebMock.stub_request(:post, "https://api.travis-ci.com/job/#{job.id}/restart").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => '', :headers => {})

    find_button('Restart').trigger('click')

    expect(page).to have_text('Job successfully restarted.')
  end
end