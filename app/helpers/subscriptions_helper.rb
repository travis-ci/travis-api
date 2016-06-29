module SubscriptionsHelper
  def format_price(amount)
    number_to_currency(amount.to_f/100)
  end

  def format_subscription(name)
    name.selected_plan.gsub(/-/, ' ').remove('travis ci')
  end
end
