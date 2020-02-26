module InvoiceHelper
  def invoice_amount(invoice)
    invoice_object = invoice.object
    invoice_object = invoice_object['object'] if invoice_object['object'].is_a?(Hash)
    invoice_object.fetch('amount_due')
  end
end
