require 'rails_helper'

RSpec.feature 'GDPR export', js: true, type: :feature do
  let!(:user) { create(:user, id: 5, login: 'travisbot') }

  scenario 'User enables a global feature' do
    visit "users/5/gdpr"

    #find_button("Export travisbot's data in").trigger('click')
  end
end
