require 'rails_helper'

RSpec.feature 'Update subscription information', js: true, type: :feature do
  let!(:billing_url) { 'https://billing-fake.travis-ci.com' }
  let!(:auth_key) { 'fake_auth_key' }
  let!(:user) { create :user_with_active_subscription}
  let!(:subscription) { user.subscription }

  scenario 'Update expiry date for User' do
    stubbed_request = stub_billing_request(:patch, "/subscriptions/#{subscription.id}/address", auth_key: auth_key, user_id: user.id)
                      .with(:body => {"billing_email"=>"contact@travis-ci.com", "valid_to" => 2.weeks.from_now.to_date.strftime("%Y-%m-%d"), "vat_id"=>"DE999999998"})
                      .to_return(status: 204)

    visit "/users/#{user.id}/subscription"
    click_on('Subscription')

    fill_in('subscription_valid_to', with: 2.weeks.from_now.to_date)
    fill_in('subscription_vat_id', :with => 'DE999999998')

    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travisbot's subscription: valid_to changed from #{1.week.from_now.to_date} to #{2.week.from_now.to_date}")
    expect(stubbed_request).to have_been_made
  end

  scenario 'Update VAT ID and billing email' do
    stubbed_request = stub_billing_request(:patch, "/subscriptions/#{subscription.id}/address", auth_key: auth_key, user_id: user.id)
                           .with(:body => {"billing_email"=>"contact@travis-ci.org", "valid_to" => 1.weeks.from_now.to_date.strftime("%Y-%m-%d"), "vat_id"=>"DE999999998"})
                           .to_return(status: 204)

    visit "/users/#{user.id}/subscription"
    click_on('Subscription')

    fill_in('subscription_vat_id', :with => 'DE999999998')
    fill_in('subscription_billing_email', :with => 'contact@travis-ci.org')

    find_button('Update').trigger('click')

    expect(page).to have_text("Updated travisbot's subscription: billing_email changed from contact@travis-ci.com to contact@travis-ci.org, vat_id changed from DE999999999 to DE999999998")
    expect(stubbed_request).to have_been_made
  end

  scenario 'Update VAT ID with invalid VAT ID' do
    stubbed_request = stub_billing_request(:patch, "/subscriptions/#{subscription.id}/address", auth_key: auth_key, user_id: user.id)
                           .with(:body => {"billing_email"=>"contact@travis-ci.org", "valid_to" => 1.weeks.from_now.to_date.strftime("%Y-%m-%d"), "vat_id"=>"DE99999"})
                           .to_return(status: 422, body: '{"error":"Vat is not a valid German vat number"}')

    visit "/users/#{user.id}/subscription"
    click_on('Subscription')

    fill_in('subscription_vat_id', :with => 'DE99999')
    fill_in('subscription_billing_email', :with => 'contact@travis-ci.org')

    find_button('Update').trigger('click')

    expect(page).to have_text("Vat is not a valid German vat number")
    expect(stubbed_request).to have_been_made
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
    WebMock.stub_request(method, url).with(basic_auth: ['_', auth_key], headers: { 'X-Travis-User-Id' => user_id , "Content-Type"=>"application/x-www-form-urlencoded", "User-Agent"=>"Faraday v0.9.2"})
  end
end