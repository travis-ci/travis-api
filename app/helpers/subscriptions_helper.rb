module SubscriptionsHelper
  def format_price(amount)
    number_to_currency(amount.to_f/100)
  end
end
