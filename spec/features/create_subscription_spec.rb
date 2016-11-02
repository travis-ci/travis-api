require 'rails_helper'

RSpec.feature 'Create a free subscription', js: true, type: :feature do
  let(:user)         { create :user, login: 'lisbethmarianne', name: 'Katrin' }
  let(:organization) { create :organization, login: 'rubymonstas', name: 'Rubymonstas'}

  scenario 'Create a one build subscription for user' do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/users/#{user.id}"
    find_button('create-subscription').trigger('click')

    expect(page).to have_text("Created a new subscription for Katrin (lisbethmarianne)")

    # Capybara needs this extra click
    click_on('User')

    expect(page).to have_text("active, one build, expires #{1.year.from_now.to_date}")
  end

  scenario 'Create a two builds subscription for organization' do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/organizations/#{organization.id}"
    select('two builds', from: 'subscription_selected_plan')
    find_button('create-subscription').trigger('click')

    expect(page).to have_text("Created a new subscription for Rubymonstas (rubymonstas)")

    # Capybara needs this extra click
    click_on('Organization')

    expect(page).to have_text("active, two builds, expires #{1.year.from_now.to_date}")
  end
end
