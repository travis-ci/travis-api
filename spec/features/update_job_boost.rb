require 'rails_helper'

RSpec.feature "Update Job Boost", js: true, type: :feature do
  let!(:user) { create(:user, name: "Klaus", login: "klaus_maus") }

  scenario "Update job boost limit and time for a user" do
    visit "/users/#{user.id}"

    fill_in('boost_owner_limit', with: '2')
    fill_in('boost_expires_after', with: '12')
    find_button("update-job-boost").trigger('click')

    expect(page).to have_text("Owner limit set to 2, and expires after 12 hours.")
    expect(page).to have_field('boost_owner_limit', with: '2')
    expect(page).to have_field('boost_expires_after', with: '12.0')
  end

  scenario "Update job boost limit for a user" do
    visit "/users/#{user.id}"

    fill_in('boost_owner_limit', with: '2')
    find_button("update-job-boost").trigger('click')

    expect(page).to have_text("Owner limit set to 2, and expires after 24 hours.")
    expect(page).to have_field('boost_owner_limit', with: '2')
    expect(page).to have_field('boost_expires_after', with: '24.0')
  end
end
