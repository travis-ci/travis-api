require 'rails_helper'

RSpec.feature 'Manage preferences on Organization and User pages', js: true, type: :feature do
  let!(:katrin)              { create(:user, login: 'lisbethmarianne') }
  let!(:organization)        { create(:organization, users: [katrin]) }

  scenario 'Organization page contains Preferences section with keep_netrc option, checkbox and button' do
    visit "/organizations/#{organization.id}"
    expect(page).to have_text('Preferences')
    expect(page).to have_text('Keep .netrc file at start of build')
    expect(page.find_by_id('update-org-netrc')).to be_present
    expect(page.find_by_id('keep-netrc-chckbox')).to be_present
  end

  scenario 'Organization page: keep_netrc option is true by default, unsetting and setting back changes obj state' do
    visit "/organizations/#{organization.id}"
    expect(page.find_by_id('keep-netrc-chckbox')).to be_checked

    find_by_id('keep-netrc-chckbox').set false
    find_by_id('update-org-netrc').click
    expect(Organization.find(organization.id).keep_netrc).to be false
    expect(page).to have_text('Set keep_netrc to false for travis-pro.')

    find_by_id('keep-netrc-chckbox').set true
    find_by_id('update-org-netrc').click
    expect(Organization.find(organization.id).keep_netrc).to be true
    expect(page).to have_text('Set keep_netrc to true for travis-pro.')
  end

  scenario 'User page contains Preferences section with keep_netrc option, checkbox and button' do
    visit "/users/#{katrin.id}"
    expect(page).to have_text('Preferences')
    expect(page).to have_text('Keep .netrc file at start of build')
    expect(page.find_by_id('update-usr-netrc')).to be_present
    expect(page.find_by_id('keep-netrc-chckbox')).to be_present
  end

  scenario 'User page: keep_netrc option is true by default, unsetting and setting back changes obj state' do
    visit "/users/#{katrin.id}"
    expect(page.find_by_id('keep-netrc-chckbox')).to be_checked

    find_by_id('keep-netrc-chckbox').set false
    find_by_id('update-usr-netrc').click
    expect(User.find(katrin.id).keep_netrc).to be false
    expect(page).to have_text('Set keep_netrc to false for lisbethmarianne.')

    find_by_id('keep-netrc-chckbox').set true
    find_by_id('update-usr-netrc').click
    expect(User.find(katrin.id).keep_netrc).to be true
    expect(page).to have_text('Set keep_netrc to true for lisbethmarianne.')
  end
end
