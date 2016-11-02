require 'rails_helper'

RSpec.feature "Hide Broadcast", js: true, type: :feature do
  let!(:broadcast) { create(:broadcast, message: 'Some message text.') }

  scenario "Hide broadcast for everybody" do
    visit "/broadcasts"

    find_button('Hide').trigger('click')

    expect(page).to have_button("Display")
    expect(page).to have_no_button("Hide")
  end
end
