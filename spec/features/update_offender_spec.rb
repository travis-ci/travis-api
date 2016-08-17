require 'rails_helper'

RSpec.feature "Update Offender", :js => true, :type => :feature do
  let!(:user) { create(:user, name: "Klaus", login: "klaus_maus") }

  scenario "Update abuse status of a user" do
    visit "/user/#{user.id}"
    click_on("Account")

    find("#offender_offenders").trigger('click')
    find_button('Update').trigger('click')

    expect(page).to have_text("Abuse settings for Klaus (klaus_maus) updated.")
  end
end
