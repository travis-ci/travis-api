require 'rails_helper'

RSpec.feature "Update trial builds", :js => true, :type => :feature do
  let!(:user)  { create(:user) }

  before { Travis::DataStores.redis.set("trial:#{user.login}", '10') }

  scenario "Update trial builds for a user" do
    allow_any_instance_of(UsersController).to receive(:builds_provided_for).and_return(10)

    visit "/user/#{user.id}"
    click_on("Account")

    expect(page).to have_text("Builds Provided:10")
    expect(page).to have_selector("input#builds_remaining[value='10']")

    fill_in "builds_remaining", with: "60"
    find_button('Update').trigger('click')

    allow_any_instance_of(UsersController).to receive(:update_topaz).with(user, '60', '10')

    expect(page).to have_text("Reset sinthetix's trial to 60 builds.")

    # add some tests that show that Builds Provided and Builds Remaining got updated
  end
end
