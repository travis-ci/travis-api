require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe '#as_pdf' do
    let!(:invoice) { create(:invoice) }

    it 'creates an url to download the invoice as pdf from billing' do
      expect(invoice.as_pdf).to eql 'https://billing-fake.travis-ci.com/invoices/b999c84489715a3920f4bb3ceceeb45ea879a516.pdf'
    end
  end
end
