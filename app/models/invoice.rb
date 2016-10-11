class Invoice < ApplicationRecord
  belongs_to :subscription

  serialize :object, Hash

  def amount_due
    object['amount_due']
  end

  def as_pdf
    invoice_hash = Digest::SHA1.hexdigest(stripe_id + invoice_id)
    "#{Travis::Config.load.billing_endpoint}/invoices/#{invoice_hash}.pdf"
  end
end
