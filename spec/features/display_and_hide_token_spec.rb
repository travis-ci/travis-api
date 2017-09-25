require 'rails_helper'

RSpec.feature 'Display a users github token', js: true, type: :feature do
  let!(:user) { create(:user, login: 'lisbethmarianne', github_oauth_token: '3k0Tjf#kdlskbkjbkhvbiuviv') }

  scenario 'Display a users github token' do
    allow_any_instance_of(ROTP::TOTP).to receive(:verify).with('123456').and_return(true)

    visit "/users/#{user.id}"

    expect(page).to have_no_text('3k0Tjf#kdlskbkjbkhvbiuviv')

    find_button('Display').trigger('click')

    expect(page).to have_text('This action requires a one time password')

    fill_in('otp', with: '123456')
    find_button('Confirm').trigger('click')

    expect(page).to have_text('3k0Tjf#kdlskbkjbkhvbiuviv')
    expect(page).to have_button('Hide')
    expect(page).to have_no_button('Display')

    find_button('Hide').trigger('click')

    expect(page).to have_no_text('3k0Tjf#kdlskbkjbkhvbiuviv')
    expect(page).to have_button('Display')
    expect(page).to have_no_button('Hide')
  end
end
