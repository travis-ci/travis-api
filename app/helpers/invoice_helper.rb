module InvoiceHelper
  def invoice_amount(invoice)
    return invoice.amount_due.nil? ? 0 : invoice.amount_due if invoice.is_a?(Travis::Models::Billing::Invoice)

    invoice_object = invoice.object
    invoice_object = invoice_object['object'] if invoice_object['object'].is_a?(Hash)
    invoice_object.fetch('amount_due')
  end
end
