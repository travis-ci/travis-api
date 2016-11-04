require 'rails_helper'

RSpec.feature 'Reset 2FA for user', js: true, type: :feature do
  let(:redis)  { Travis::DataStores.redis }

  before { redis.set('admin-v2:otp:travisbot', 'secret') }

  scenario 'Reset 2FA successfully' do
    allow_any_instance_of(ROTP::TOTP).to receive(:verify).with('123456').and_return(true)

    visit '/admins'
    find_button('Reset Secret').trigger('click')
    expect(page).to have_text('This action requires a one time password close If you are 100% certain, please verify your identity by providing a one time password:')

    fill_in('otp', with: '123456')
    find_button('Confirm').trigger('click')
    expect(page).to have_text('Secret for travisbot has been reset.')
  end

  scenario 'Reset 2FA with wrong OTP' do
    allow_any_instance_of(ROTP::TOTP).to receive(:verify).with('345678').and_return(false)

    visit '/admins'
    find_button('Reset Secret').trigger('click')
    expect(page).to have_text('This action requires a one time password close If you are 100% certain, please verify your identity by providing a one time password:')

    fill_in('otp', with: '345678')
    find_button('Confirm').trigger('click')
    expect(page).to have_text('One time password did not match, please try again.')
  end
end
