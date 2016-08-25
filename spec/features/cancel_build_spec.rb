require 'rails_helper'

RSpec.feature 'Cancel a Build', :js => true, :type => :feature do
  let!(:repository) { create(:repository) }
  let!(:build) { create(:build, repository: repository, started_at: '2016-06-29 11:06:01', finished_at: nil, state: 'started', config: {}) }

  scenario 'User cancels a build' do
    visit "/build/#{build.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/build/#{build.id}/cancel").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => '', :headers => {})

    find_button('Cancel').trigger('click')

    expect(page).to have_text('Build travis-pro/travis-admin#456 successfully canceled.')
  end

  scenario 'User cancels a build via builds tab in repository view' do
    visit "/repository/#{repository.id}#builds"
    click_on("Builds")

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/build/#{build.id}/cancel").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => '', :headers => {})

    find_link('Cancel').trigger('click')

    expect(page).to have_text('Build travis-pro/travis-admin#456 successfully canceled.')
    expect(page).to have_link('Canceled')
  end
end
