require 'rails_helper'

RSpec.feature 'Update subscription information', js: true, type: :feature do

  before do
    TravisConfig.load.billing.url = billing_url
    TravisConfig.load.billing.auth_key = auth_key
  end

  let!(:user) { create :user_with_active_subscription}
  let!(:subscription) { create :subscription, owner: user}
	let!(:billing_url) { 'https://billing.travis-ci.com/' }
	let!(:auth_key) { 'supersecret' }
  let!(:subscription_params) { { 'vat_id' => 'DE999999998' } }
  let!(:billing_update_service) { Services::BillingUpdate.new(subscription , subscription_params)}
  let!(:country) { 'Germany' }


  scenario 'Update expiry date for User' do
    stub_billing_request(:patch, "/subscriptions/#{subscription.id}/address", auth_key: auth_key, user_id: user.id)
          .with(body: JSON.dump(subscription_params))
          .to_return(status: 204)

    visit "/users/#{user.id}/subscription"
    click_on('Subscription')

    fill_in('subscription_valid_to', with: 2.weeks.from_now.to_date)
    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travisbot's subscription: valid_to changed from #{1.week.from_now.to_date} to #{2.week.from_now.to_date}")
    expect(page).to have_field('subscription_valid_to', with: 2.weeks.from_now.to_date)
    # expect(billing_update_service).to have_been_made.once

    # expect { billing_update_service }.to_not raise_error
    # expect(stubbed_request).to have_been_made
  end

  scenario 'Update VAT ID and billing email' do
    visit "/users/#{user.id}/subscription"
    click_on('Subscription')

    fill_in('subscription_vat_id', :with => 'DE999999998')
    fill_in('subscription_billing_email', :with => 'contact@travis-ci.org')

    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travisbot's subscription: billing_email changed from contact@travis-ci.com to contact@travis-ci.org, vat_id changed from DE999999999 to DE999999998")
    expect(page).to have_field('subscription_vat_id', with: 'DE999999998')
    expect(page).to have_field('subscription_billing_email', with: 'contact@travis-ci.org')
		expect(update_stubbed_request).to have_been_made.once
	end

  scenario 'No changes made to subscription' do
    visit "/users/#{user.id}/subscription"

    find_button('Update').trigger('click')
    expect(page).to have_text ('No subscription changes were made.')
    expect(page).to have_field('subscription_vat_id', with: 'DE999999999')
  end

  def stub_billing_request(method, path, auth_key:, user_id:)
    url = URI(billing_url).tap do |url|
      url.path = path
    end.to_s
    stub_request(method, url).with(basic_auth: ['_', auth_key], headers: { 'X-Travis-User-Id' => user_id })
  end

end
