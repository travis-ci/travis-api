require 'rails_helper'

RSpec.feature 'Update subscription information', js: true, type: :feature do
  let!(:user) { create :user_with_active_subscription}

  scenario 'Update expiry date for User' do
    visit "/users/#{user.id}#subscription"
    click_on('Subscription')

    fill_in('subscription_valid_to', with: 2.weeks.from_now.to_date)
    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travisbot's subscription: valid_to changed from #{1.week.from_now.to_date} to #{2.week.from_now.to_date}")
    expect(page).to have_field('subscription_valid_to', with: 2.weeks.from_now.to_date)
  end

  scenario 'Update VAT ID and billing email' do
    visit "/users/#{user.id}#subscription"
    click_on('Subscription')

    fill_in('subscription_vat_id', :with => 'DE999999998')
    fill_in('subscription_billing_email', :with => 'contact@travis-ci.org')

    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travisbot's subscription: billing_email changed from contact@travis-ci.com to contact@travis-ci.org, vat_id changed from DE999999999 to DE999999998")
    expect(page).to have_field('subscription_vat_id', with: 'DE999999998')
    expect(page).to have_field('subscription_billing_email', with: 'contact@travis-ci.org')
  end

  scenario 'No changes made to subscription' do
    visit "/users/#{user.id}#subscription"

    find_button('Update').trigger('click')
    expect(page).to have_text ('No subscription changes were made.')
    expect(page).to have_field('subscription_vat_id', with: 'DE999999999')
  end
end
