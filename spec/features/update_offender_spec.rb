require 'rails_helper'

RSpec.feature 'Update Offender', js: true, type: :feature do
  let!(:user) { create(:user) }

  scenario 'Update abuse status of a user' do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/users/#{user.id}"

    find('#offender_offenders').trigger('click')
    find_button('update-abuse-status').trigger('click')

    expect(page).to have_text('Abuse settings for Travis (travisbot) updated.')
    expect(page.has_checked_field?('offender[offenders]')).to be true
  end
end
