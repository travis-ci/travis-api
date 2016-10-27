require 'rails_helper'

RSpec.feature "Create Broadcast", js: true, type: :feature do
  let!(:user)         { create(:user) }
  let!(:organization) { create(:organization) }
  let!(:repository)   { create(:repository) }

  scenario 'Create broadcast for everybody' do
    visit '/broadcasts'

    fill_in('broadcast_message', :with => 'This is a message.')
    choose('Warning')
    find_button('Create').trigger('click')


    expect(page).to have_text('Broadcast created.')
    expect(page).to have_text('This is a message.')
  end

  scenario "Create broadcast for user" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/users/#{user.id}#broadcasts"

    fill_in('broadcast_message', with: 'This is a message.')
    find_button('Create').trigger('click')

    expect(page).to have_text('Broadcast created.')
    expect(page).to have_text('This is a message.')
  end

  scenario 'Create broadcast for organization' do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/organizations/#{organization.id}#broadcasts"

    fill_in('broadcast_message', with: 'This is a message.')
    find_button('Create').trigger('click')

    expect(page).to have_text('Broadcast created.')
    expect(page).to have_text('This is a message.')
  end

  scenario 'Create broadcast for repository' do
    visit "/repositories/#{repository.id}#broadcasts"

    fill_in('broadcast_message', with: 'This is a message.')
    find_button('Create').trigger('click')

    expect(page).to have_text('Broadcast created.')
    expect(page).to have_text('This is a message.')
  end
end
