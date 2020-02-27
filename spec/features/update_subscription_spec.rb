require 'rails_helper'

RSpec.feature 'Update subscription information', js: true, type: :feature do
  let!(:user) { create :user_with_active_subscription}
	let!(:stup_vat_rate_list) do
		stub_request(:get, 'https://api.stripe.com/v1/tax_rates?limit=50')
			.to_return(status: 200, body: JSON.dump(
				object: 'list',
				url: '/v1/tax_rates',
				has_more: false,
				data: [{
								 id: 'txr_1FeeUY2eZvKYlo2CF3XQrEBu',
								 object: 'tax_rate',
								 active: true,
								 created: '1573723194',
								 description: 'VAT Germany',
								 display_name: 'VAT',
								 inclusive: false,
								 jurisdiction: 'Germany',
								 livemode: false,
								 metadata: {},
								 percentage: 19.0
							 }]
			))
	end
	let!(:update_stubbed_request) do
		stub_request(:post, "https://api.stripe.com/v1/subscriptions/sub_123")
			.to_return(body: JSON.dump(id: 'sub_123'))
	end
	let!(:customer_stubbed_request) do
		stub_request(:get, 'https://api.stripe.com/v1/customers/cus_123')
			.to_return(status: 200, body: JSON.dump(
				id: 'cus_123',
				subscription:{ id: 'sub_123', object: 'subscription', status: 'active' }))
	end
	let(:subscription) { create :subscription, country: country}
	let(:country) { 'Germany' }

  scenario 'Update expiry date for User' do
    visit "/users/#{user.id}/subscription"
    click_on('Subscription')

    fill_in('subscription_valid_to', with: 2.weeks.from_now.to_date)
    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travisbot's subscription: valid_to changed from #{1.week.from_now.to_date} to #{2.week.from_now.to_date}")
    expect(page).to have_field('subscription_valid_to', with: 2.weeks.from_now.to_date)
		expect(update_stubbed_request).to_not have_been_made.once
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
end
