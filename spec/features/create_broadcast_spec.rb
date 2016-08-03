require 'rails_helper'

RSpec.feature "Create Broadcast", :js => true, :type => :feature do
  let!(:user)         { create(:user) }
  let!(:organization) { create(:organization) }
  let!(:repository)   { create(:repository) }

  scenario "Create broadcast for everybody" do
    visit "/broadcast"

    fill_in('broadcast_message', :with => 'This is a message.')
    choose("Warning")
    find_button('Create').trigger('click')


    expect(page).to have_text("Broadcast created.")
    expect(page).to have_text("This is a message.")
  end

  scenario "Create broadcast for user" do
    visit "/user/#{user.id}#broadcast"

    find_button('Create').trigger('click')

    expect(page).to have_text("Broadcast created.")
  end

  scenario "Create broadcast for organization" do
    visit "/organization/#{organization.id}#broadcast"

    find_button('Create').trigger('click')

    expect(page).to have_text("Broadcast created.")
  end

  scenario "Create broadcast for repository" do
    visit "/repository/#{repository.id}#broadcast"

    find_button('Create').trigger('click')

    expect(page).to have_text("Broadcast created.")
  end
end
