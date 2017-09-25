require 'rails_helper'

RSpec.feature 'Update trial builds', js: true, type: :feature do
  let!(:user) { create(:user) }

  before { Travis::DataStores.redis.set("trial:#{user.login}", '10') }

  scenario 'Update trial builds for a user' do
    visit "/users/#{user.id}"

    click_on('User')

    #TODO - Joe to add expectations
  end
end
