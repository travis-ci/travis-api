require 'rails_helper'

RSpec.feature "Update Offender", :js => true, :type => :feature do
  let!(:user) { create(:user, name: "Klaus", login: "klaus_maus") }

  scenario "Update abuse status of a user" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/users/#{user.id}"
    click_on('User') #Capybara seems to be demanding this

    find("#offender_offenders").trigger('click')
    find_button("update-abuse-status").trigger('click')

    expect(page).to have_text("Abuse settings for Klaus (klaus_maus) updated.")

    expect(page.has_checked_field?("offender[offenders]")).to be true
  end
end
