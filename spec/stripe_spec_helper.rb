require 'rails_helper'

module StripeSpecHelper
  def stripe_event(type, data, extra = {})
    params = { type: type, id: random_id(:ev), data: { object: data } }.merge(extra)
    Stripe::Event.construct_from(params)
  end

  def stripe_subscription(data = {})
    Stripe::Subscription.construct_from({ id: random_id(:sub), object: 'subscription' }.merge(data))
  end

  def stripe_customer(data = {})
    Stripe::Customer.construct_from({ id: random_id(:cus), object: 'customer' }.merge(data))
  end

  def stripe_invoice(data = {})
    Stripe::Invoice.construct_from({ id: random_id(:in), object: 'invoice' }.merge(data))
  end

  def stripe_charge(data = {})
    Stripe::Charge.construct_from({ id: random_id(:ch), object: 'charge' }.merge(data))
  end

  def stripe_refund(data = {})
    Stripe::Refund.construct_from({ id: random_id(:re), object: 'refund' }.merge(data))
  end

  def stripe_coupon(data = {})
    Stripe::Coupon.construct_from({ object: 'coupon' }.merge(data))
  end

  def stripe_card(data = {})
    Stripe::Card.construct_from({ object: 'card' }.merge(data))
  end

  def payment_method_details(data = {})
    Stripe::Card.construct_from(card: stripe_card(data))
  end

  def stripe_payment_intent(data = {})
    Stripe::StripeObject.construct_from({ object: 'card' }.merge(data))
  end

  def stripe_list(*items)
    Stripe::ListObject.construct_from(object: 'list', data: items)
  end

  LINE_ITEM_TYPES = %w[invoiceitem subscription].freeze
  def stripe_line_item(data = {})
    raise "Type must be one of #{LINE_ITEM_TYPES.inspect}, not #{data[:type].inspect}" unless LINE_ITEM_TYPES.include?(data[:type])

    Stripe::InvoiceLineItem.construct_from({ id: random_id(:ii), object: 'line_item' }.merge(data))
  end

  def stripe_tax(data = {})
    Stripe::TaxRate.construct_from({ object: 'tax_rate' }.merge(data))
  end

  def stripe_plan(data = {})
    Stripe::Plan.construct_from({ object: 'plan' }.merge(data))
  end

  def random_id(prefix)
    "#{prefix}_#{rand(999_999)}"
  end
end
