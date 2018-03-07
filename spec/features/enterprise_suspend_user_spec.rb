require 'rails_helper'

RSpec.feature 'suspend/unsuspend a user in enterprise mode', js: true, type: :feature do
  let!(:user) { create(:user) }

  before { Rails.configuration.travis_config.enterprise = true }
  after { Rails.configuration.travis_config.enterprise = false }

  scenario 'suspending' do
    visit "/enterprise_users"

    expect(page).not_to have_text /Suspended on/

    within(:css, "#user-#{user.id}") do
      find_button('Suspend').trigger('click')
    end

    expect(page).to have_text(/Suspended on/)
  end

  scenario 'unsuspending' do
    user.update_attributes!(suspended: true, suspended_at: Time.now)

    visit "/enterprise_users"

    expect(page).to have_text /Suspended on/

    within(:css, "#user-#{user.id}") do
      find_button('Unsuspend').trigger('click')
    end

    expect(page).not_to have_text(/Suspended on/)
  end
end
