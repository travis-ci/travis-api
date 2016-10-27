require 'rails_helper'

RSpec.feature 'update subscription information', :js => true, :type => :feature do
  let!(:user) { create :user, login: 'travis-ci' }
  let!(:organization) { create :organization, login: 'travis-pro' }
  let!(:user_subscription) { create :subscription, owner: user, cc_token: 'tok_1076247Biz', valid_to: 1.week.from_now, vat_id: 'DE999999999', billing_email: 'contact@travis-ci.com', selected_plan: 'travis-ci-five-builds'}
  let!(:user_plan) { create :plan, amount: 249, subscription: user_subscription }
  let!(:org_subscription) { create :subscription, owner: organization, cc_token: 'tok_1076247Biz', valid_to: 1.week.from_now, vat_id: 'DE999999999', billing_email: 'contact@travis-ci.com', selected_plan: 'travis-ci-five-builds'}
  let!(:org_plan) { create :plan, amount: 249, subscription: org_subscription }

  before { allow(Travis::DataStores.topaz).to receive(:builds_provided_for) }

  scenario 'Update expiry date for User' do
    visit "/users/#{user.id}#subscription"

    fill_in('subscription_valid_to', with: 2.weeks.from_now.to_date)
    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travis-ci's subscription: valid_to changed from #{1.week.from_now.to_date} to #{2.week.from_now.to_date}")
    expect(page).to have_field('subscription_valid_to', with: 2.weeks.from_now.to_date)
  end

  scenario 'Update VAT ID and billing email for Organization' do
    visit "/organizations/#{organization.id}#subscription"

    fill_in('subscription_vat_id', :with => 'DE999999998')
    fill_in('subscription_billing_email', :with => 'contact@travis-ci.org')
    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travis-pro's subscription: billing_email changed from contact@travis-ci.com to contact@travis-ci.org, vat_id changed from DE999999999 to DE999999998")
    expect(page).to have_field('subscription_vat_id', with: 'DE999999998')
    expect(page).to have_field('subscription_billing_email', with: 'contact@travis-ci.org')
  end

  scenario 'No changes made to User subscription' do
    visit "/users/#{user.id}#subscription"
    find_button('Update').trigger('click')
    expect(page).to have_text ('No subscription changes were made.')
    expect(page).to have_field('subscription_vat_id', with: 'DE999999999')
  end

  scenario 'No changes made to Organization subscription' do
    visit "/organizations/#{user.id}#subscription"
    find_button('Update').trigger('click')
    expect(page).to have_text ('No subscription changes were made.')
    expect(page).to have_field('subscription_vat_id', with: 'DE999999998')
  end
end
