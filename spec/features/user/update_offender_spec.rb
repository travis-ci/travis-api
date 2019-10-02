require 'rails_helper'

RSpec.feature 'Update Offender', js: true, type: :feature do
  before do
    user = create(:user)
    visit "/users/#{user.id}"
  end

  scenario 'Update abuse status of a user' do
    find('#offender_abuse_offenders').trigger('click')
    find_button('update-abuse-status').trigger('click')

    expect(page).to have_text('Abuse settings for Travis (travisbot) updated.')
    expect(page.has_checked_field?('offender_abuse_offenders')).to be true
  end

  scenario 'Update offender reason' do
    find('#offender_abuse_offenders').trigger('click')
    fill_in('offender_reason', with: 'Test Reason')
    find_button('update-abuse-status').trigger('click')

    within('.abuse-reasons') do
      expect(page).to have_text('Explanation: Updated manually, through admin: Test Reason')
    end
  end
end
