require 'rails_helper'
require 'csv'

RSpec.feature 'Update address' do
  let!(:billing_url) { 'https://billing-fake.travis-ci.com' }
  let!(:auth_key) { 'fake_auth_key' }
  let!(:user) { create :user_with_active_subscription}
  let!(:subscription) { user.subscription }
  let!(:subscription_params) { { 'address' => 'Rigaer Strasse' } }
  let!(:from ) { '2019-12-05' }
  let!(:to ) { '2019-12-05' }
  let!(:type ) { 'invoice' }

  describe '#update_address' do
    let(:billing_client_service) { Services::BillingClient.new }

    it 'requests the update' do
      stubbed_request = stub_billing_request(:patch, "/subscriptions/#{subscription.id}/address", auth_key: auth_key, user_id: user.id)
                            .with(:body => subscription_params)
                            .to_return(status: 204)

      expect {billing_client_service.update_address_request(subscription, subscription_params) }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#csv_import' do
    let(:billing_client_service) { Services::BillingClient.new }

    it 'csv import' do
      stubbed_request = WebMock.stub_request(:get, "#{billing_url}/report?from=#{from}&to=#{to}")
                        .with(headers: { Authorization: 'Token token=' << auth_key , "User-Agent"=>"Faraday v0.9.2"})
                        .to_return(status: 200,
                                   body: "Invoice Date,Product Type,Invoice Number,Status,Plan Name\n"+"2020-01-01,Hosted Monthly,4F92070-0035,paid,travis-ci-two-builds")



      expect {billing_client_service.csv_import(from, to, type) }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  def stub_billing_request(method, path, auth_key:, user_id:)
    url = URI(billing_url).tap do |url|
      url.path = path
    end.to_s
    WebMock.stub_request(method, url).with(basic_auth: ['_', auth_key], headers: { 'X-Travis-User-Id' => user_id , "Content-Type"=>"application/x-www-form-urlencoded", "User-Agent"=>"Faraday v0.9.2"})
  end

end
