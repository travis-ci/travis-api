require 'rails_helper'

RSpec.describe Services::Stripe do
  subject { described_class.new }
  let(:user) { create(:user) }
	let(:subscription) { create :subscription }
  let(:stripe_service) { Services::Stripe.new }
  let(:tax_id) { ['txr_1FeeUY2eZvKYlo2CF3XQrEBu'] }
  describe '#fetch_customer' do

	let!(:stubbed_request) do
		WebMock.stub_request(:get, 'https://api.stripe.com/v1/customers/cus_123')
			.to_return(status: 200, body: JSON.dump(id: 'cus_123'))
	end

    it 'successfully fetches the customer' do
      subject.fetch_customer(subscription)
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#update_subscription' do
    let(:options) { { cancel_at_period_end: false } }
    let(:subscription) { stripe_subscription(status: 'incomplete', canceled_at: nil, cancel_at: nil, cancel_at_period_end: false) }
    let!(:stubbed_request) do
      stub_request(:post, "https://api.stripe.com/v1/subscriptions/sub_123")
        .to_return(body: JSON.dump(id: 'sub_123'))
    end

    it 'successfully updates the subscription' do
      subject.update_subscription(subscription.id, options)
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#fetch_tax_rates' do
    let!(:stubbed_vat_rate_list) do
      stub_request(:get, 'https://api.stripe.com/v1/tax_rates?limit=50')
        .to_return(status: 200, body: JSON.dump(
          object: 'list',
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
    it 'successfully fetches upcoming invoice' do
      subject.tax_rates
      expect(stubbed_vat_rate_list).to have_been_made
    end
  end
end
