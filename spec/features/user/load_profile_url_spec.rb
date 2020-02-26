require 'rails_helper'

RSpec.feature 'Load Profile Url', js: true, type: :feature do
  scenario 'Load profile URL depending on vcs type' do
    user = create(:user, vcs_type: 'GithubUser', login: 'travis')
    visit "/users/#{user.id}"

    expect(page).to have_selector(:css, 'a[href="https://github.com/travis"]')
  end

  scenario 'When provieder is unknown' do
    user = create(:user, vcs_type: 'Unknown', login: 'travis')
    visit "/users/#{user.id}"

    expect(page).to have_selector(:css, 'a[href=""]')
  end
end
