require 'rails_helper'

RSpec.feature 'Create a Broadcast', js: true, type: :feature do
  let!(:user)         { create(:user) }
  let!(:organization) { create(:organization) }
  let!(:repository)   { create(:repository) }

  before {
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
  }

  scenario 'Create a broadcast for everybody' do
    visit '/broadcasts'

    fill_in('broadcast_message', :with => 'This is a message.')
    choose('Warning')
    find_button('Create').trigger('click')


    expect(page).to have_text('Broadcast created.')
    expect(page).to have_text('This is a message.')
  end

  scenario 'Create a broadcast for user' do
    visit "/users/#{user.id}#broadcasts"

    fill_in('broadcast_message', with: 'This is a message.')
    find_button('Create').trigger('click')

    expect(page).to have_text('Broadcast created.')

    click_on('Broadcasts')
    expect(page).to have_text('This is a message.')
  end

  scenario 'Create a broadcast for organization' do
    visit "/organizations/#{organization.id}#broadcasts"

    fill_in('broadcast_message', with: 'This is a message.')
    find_button('Create').trigger('click')

    expect(page).to have_text('Broadcast created.')

    click_on('Broadcasts')
    expect(page).to have_text('This is a message.')
  end

  scenario 'Create a broadcast for repository' do
    visit "/repositories/#{repository.id}#broadcasts"

    fill_in('broadcast_message', with: 'This is a message.')
    find_button('Create').trigger('click')

    expect(page).to have_text('Broadcast created.')

    click_on('Broadcasts')
    expect(page).to have_text('This is a message.')
  end
end
