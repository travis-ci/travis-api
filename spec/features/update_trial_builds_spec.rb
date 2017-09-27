require 'rails_helper'

RSpec.feature 'Update trial builds', js: true, type: :feature do
  let!(:user) { create(:user) }

  before do
    user.trials.create.tap do |t|
      t.trial_allowances.create(creator: user, builds_allowed: 10, builds_remaining: 10)
    end
    Travis::DataStores.redis.set("trial:#{user.login}", '10')
  end

  scenario 'Update trial builds for a user' do
    visit "/users/#{user.id}"
    click_on('User')
    fill_in('builds_allowed', with: '100')
    find_button('Add').trigger('click')
    expect(page).to have_text /Added 100 trial builds for/
  end
end
