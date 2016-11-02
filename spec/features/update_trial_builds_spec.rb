require 'rails_helper'

RSpec.feature "Update trial builds", js: true, type: :feature do
  let!(:user) { create(:user) }

  before { Travis::DataStores.redis.set("trial:#{user.login}", '10') }

  scenario "Update trial builds for a user" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for).and_return(20, 80)
    allow(Travis::DataStores.topaz).to receive(:update)

    visit "/users/#{user.id}"

    # for Capybara to work, we need the extra click: click_on("User"),
    # otherwise save_and_open_screenshot will give an empty page that only has the tabs on the top
    click_on("User")

    expect(page).to have_text("Builds Provided: 20")
    expect(page).to have_selector("input#builds_remaining[value='10']")

    fill_in "builds_remaining", with: "60"
    find_button("update-trial-builds").trigger('click')

    expect(page).to have_text("Reset sinthetix's trial to 60 builds.")

    # Capybara needs this extra click
    click_on("User")

    expect(page).to have_text("Builds Provided: 80")
    expect(page).to have_selector("input#builds_remaining[value='60']")
  end
end
