require 'rails_helper'

RSpec.feature "Reset 2FA for user", :js => true, :type => :feature do
  let!(:user) { create(:user, login: 'travisbot') }
  let(:redis) { Travis::DataStores.redis }

  before { redis.set("admin-v2:otp:travisbot", "secret")
           allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user) }

  scenario "Reset 2FA" do
    visit "/admins"

    find_button('Reset Secret').trigger('click')
    expect(page).to have_text("This action requires a one time password close If you are 100% certain, please verify your identity by providing a one time password:")

    #fill_in('ot-password', with: '123456')
    #find_button('Confirm').trigger('click')
    #expect(page).to have_text("Secret for travisbot has been reset")
  end
end
