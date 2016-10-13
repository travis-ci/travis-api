require 'rails_helper'

RSpec.feature 'Update subscription information', :js => true, :type => :feature do
  let(:user) { create :user, login: 'travis-ci' }
  let(:subscription) { create :subscription, cc_token: 'tok_1076247Biz', valid_to: 1.week.from_now, vat_id: 'DE999999999', billing_email: 'contact@travis-ci.com', owner: user}
  let(:plan) {create :plan, amount: 249, selected_plan: 'travis-ci-five-builds', subscription: subscription }

  scenario 'Update Expiration Date' do
    visit "/subscriptions/#{subscription.id}"

    fill_in('subscription_valid_to', with: 2.weeks.from_now.to_date)
    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travis-ci's subscription: valid_to changed from #{1.week.from_now.to_date} to #{2.week.from_now.to_date}")
    expect(page).to have_field('subscription_valid_to', with: 2.weeks.from_now.to_date)
  end

  scenario 'Update VAT ID and billing email' do
    visit "/subscriptions/#{subscription.id}"

    fill_in('subscription_vat_id', :with => 'DE999999998')
    fill_in('subscription_billing_email', :with => 'contact@travis-ci.org')
    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travis-ci's subscription: billing_email changed from contact@travis-ci.com to contact@travis-ci.org, vat_id changed from DE999999999 to DE999999998")
    expect(page).to have_field('subscription_vat_id', with: 'DE999999998')
    expect(page).to have_field('subscription_billing_email', with: 'contact@travis-ci.org')
  end

  scenario 'Update Expiration Date for user' do
    visit "/users/#{user.id}#subscription"

    fill_in('subscription_valid_to', with: 2.weeks.from_now.to_date)
    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travis-ci's subscription: valid_to changed from #{1.week.from_now.to_date} to #{2.week.from_now.to_date}")
    expect(page).to have_field('subscription_valid_to', with: 2.weeks.from_now.to_date)
  end

  scenario 'Update VAT ID and billing email for user' do
    visit "/users/#{user.id}#subscription"

    fill_in('subscription_vat_id', :with => 'DE999999998')
    fill_in('subscription_billing_email', :with => 'contact@travis-ci.org')
    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travis-ci's subscription: billing_email changed from contact@travis-ci.com to contact@travis-ci.org, vat_id changed from DE999999999 to DE999999998")
    expect(page).to have_field('subscription_vat_id', with: 'DE999999998')
    expect(page).to have_field('subscription_billing_email', with: 'contact@travis-ci.org')
  end
end
