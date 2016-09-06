require 'rails_helper'

RSpec.feature 'Restart a Build', :js => true, :type => :feature do
  let!(:repository) { create(:repository) }
  let!(:build) { create(:build, repository: repository, started_at: '2016-06-29 11:06:01', finished_at: '2016-06-29 11:09:09', state: 'failed', config: {}) }

  scenario 'User restarts a build' do
    visit "/builds/#{build.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/build/#{build.id}/restart").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => '', :headers => {})

    find_button('Restart').trigger('click')

    expect(page).to have_text('Build travis-pro/travis-admin#456 successfully restarted.')
  end

  scenario 'User restarts a build via builds tab in repository view' do
    visit "/repositories/#{repository.id}#builds"
    click_on("Builds")

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/build/#{build.id}/restart").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => '', :headers => {})

    find_button('Restart').trigger('click')

    expect(page).to have_text('Build travis-pro/travis-admin#456 successfully restarted.')
    expect(page).to have_button('Restarted', disabled: true)
  end
end
