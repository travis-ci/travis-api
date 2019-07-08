require 'rails_helper'

RSpec.feature 'GDPR', js: true, type: :feature do
  let!(:user) { create(:user, id: 5, login: 'travisbot') }

  before do
    allow_any_instance_of(ROTP::TOTP).to receive(:verify).with('123456').and_return(true)
  end

  scenario 'export data' do
    allow_any_instance_of(Services::Gdpr::Client).to receive(:export).and_return(true)

    visit "users/5/gdpr"
    find_button("Export travisbot's data in 127.0.0.1").trigger('click')

    within(:css, "div.export") do
      fill_in('otp', with: '123456')
      find_button('Confirm').trigger('click')
    end

    expect(page).to have_text("Triggered user data export for user travisbot")
  end

  scenario 'purge data' do
    allow_any_instance_of(Services::Gdpr::Client).to receive(:purge).and_return(true)

    visit "users/5/gdpr"
    find_button("Purge travisbot's data in 127.0.0.1").trigger('click')

    within(:css, "div.purge") do
      fill_in('otp', with: '123456')
      find_button('Confirm').trigger('click')
    end

    expect(page).to have_text("Triggered user data purge for user travisbot")
  end
end
