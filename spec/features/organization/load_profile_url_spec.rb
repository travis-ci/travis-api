require 'rails_helper'

RSpec.feature 'Load Profile Url', js: true, type: :feature do
  scenario 'Load profile URL depending on vcs type' do
    organization = create(:organization, vcs_type: 'GithubOrganization', login: 'travis')
    visit "/organizations/#{organization.id}"

    expect(page).to have_selector(:css, 'a[href="https://github.com/travis"]')
  end

  scenario 'When provieder is unknown' do
    organization = create(:organization, vcs_type: 'Unknown', login: 'travis')
    visit "/organizations/#{organization.id}"

    expect(page).to have_selector(:css, 'a[href=""]')
  end
end
