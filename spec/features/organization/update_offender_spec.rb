require 'rails_helper'

RSpec.feature 'Update Offender', js: true, type: :feature do
  let!(:organization) { create(:organization) }

  before { visit "/organizations/#{organization.id}" }

  scenario 'Update abuse status of organization' do
    find('#offender_offenders').trigger('click')
    find_button('update-abuse-status').trigger('click')

    expect(page).to have_text('Abuse settings for Travis (travis-pro) updated.')
    expect(page.has_checked_field?('offender[offenders]')).to be true
  end

  scenario 'Update offender reason' do
    find('#offender_offenders').trigger('click')
    fill_in('offender_reason', with: 'Test Reason')
    find_button('update-abuse-status').trigger('click')

    within('.abuse-reasons') do
      expect(page).to have_text('Explanation: Updated manually, through admin: Test Reason')
    end
  end
end
