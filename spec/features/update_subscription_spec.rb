require 'rails_helper'

RSpec.feature 'Update subscription information', :js => true, :type => :feature do
  let(:user) { create :user, login: 'travis-ci' }
  let(:subscription) { create :subscription, cc_token: 'tok_1076247Biz', valid_to: 1.week.from_now, vat_id: 'DE999999999', billing_email: 'contact@travis-ci.com', owner: user, plan: plan}
  let(:plan) {create :plan }
  scenario 'Update Expiration Date' do
    visit "/subscription/#{subscription.id}"

    # Not 100% sure what to do about this
    # If we change the date input format, would we need to change this test too?
  end

  scenario 'Update VAT ID and billing email' do
    visit "/subscription/#{subscription.id}"

    fill_in('vat_id', :with => 'DE999999998')
    fill_in('billing_email', :with => 'contact@travis-ci.org')
    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travis-ci's subscription:")
    expect(page).to have_text('changed from "DE999999999" to "DE999999998"')
    expect(page).to have_text ('changed from "contact@travis-ci.com" to "contact@travis-ci.org"')
  end
end