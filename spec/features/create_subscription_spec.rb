require 'rails_helper'

RSpec.feature 'Create a free subscription', js: true, type: :feature do
  let(:user)         { create :user, login: 'lisbethmarianne', name: 'Katrin' }
  let(:organization) { create :organization, login: 'rubymonstas', name: 'Rubymonstas'}

  before { allow(Travis::DataStores.topaz).to receive(:builds_provided_for) }

  scenario 'Create a one build subscription for user' do
    visit "/users/#{user.id}"
    find_button('create-subscription').trigger('click')

    expect(page).to have_text('Created a new subscription for Katrin (lisbethmarianne)')

    click_on('User')

    expect(page).to have_text("active, one build, expires #{1.year.from_now.to_date}")
  end

  scenario 'Create a two builds subscription for organization' do
    visit "/organizations/#{organization.id}"

    select('two builds', from: 'subscription_selected_plan')
    find_button('create-subscription').trigger('click')

    expect(page).to have_text('Created a new subscription for Rubymonstas (rubymonstas)')

    click_on('Organization')

    expect(page).to have_text("active, two builds, expires #{1.year.from_now.to_date}")
  end
end
