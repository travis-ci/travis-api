require 'rails_helper'

RSpec.feature "Update Offender", :js => true, :type => :feature do
  let!(:user) { create(:user, name: "Klaus", login: "klaus_maus") }

  scenario "Update abuse status of a user" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/user/#{user.id}"
    click_on("Account")

    find("#offender_offenders").trigger('click')
    find_button("update-abuse-status").trigger('click')

    expect(page).to have_text("Abuse settings for Klaus (klaus_maus) updated.")

    # rethink this (is not working without)
    click_on("Account")
    expect(page.has_checked_field?("offender[offenders]")).to be true
  end
end
