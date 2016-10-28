require 'rails_helper'

RSpec.feature "Reset 2FA for user", :js => true, :type => :feature do
  let!(:user) { create(:user, login: 'travisbot') }
  let(:redis) { Travis::DataStores.redis }

  before { redis.set("admin-v2:otp:travisbot", "secret") }

  scenario "Reset 2FA" do
    visit "/admins"

    find_button('Reset Secret').trigger('click')

    expect(page).to have_text("Secret for travisbot has been reset")
  end
end
