require 'rails_helper'

RSpec.feature "Restart a Build", :js => true, :type => :feature do
  let!(:build) { create(:build, started_at: '2016-06-29 11:06:01', finished_at: '2016-06-29 11:09:09') }

  scenario "User restarts a build" do
    visit "/build/#{build.id}"

    WebMock.stub_request(:post, "https://api.travis-ci.com/build/#{build.id}/restart").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => '', :headers => {})

    find_link('Restart').trigger('click')

    expect(page).to have_text('Build successfully restarted.')
    %w(finished canceled errored).each{|state| expect(page).to_not have_text(state) }
  end
end