module Services
	class Stripe
		attr_reader :subscription

		def fetch_customer(subscription)
			::Stripe::Customer.retrieve(id: subscription.customer_id)
		end

		def update_subscription(subscription_id, data)
			::Stripe::Subscription.update(subscription_id, data)
		end

		def tax_rates
			::Stripe::TaxRate.list(limit: 50)
		end

	end
end


