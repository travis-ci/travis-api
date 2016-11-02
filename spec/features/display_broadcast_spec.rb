require 'rails_helper'

RSpec.feature "Display Broadcast", js: true, type: :feature do
  let!(:broadcast) { create(:broadcast, message: 'Some message text.', expired: true) }

  scenario "Display broadcast for everybody" do
    visit "/broadcasts"

    find_button('Display').trigger('click')

    expect(page).to have_button("Hide")
    expect(page).to have_no_button("Display")
  end
end
