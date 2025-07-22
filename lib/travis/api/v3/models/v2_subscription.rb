module Travis::API::V3
  class Models::V2Subscription
    include Models::Owner

    attr_reader :id, :plan, :permissions, :source, :billing_info, :credit_card_info, :owner, :status, :valid_to, :canceled_at,
                :client_secret, :payment_intent, :addons, :auto_refill, :available_standalone_addons, :created_at, :scheduled_plan_name,
                :cancellation_requested, :current_trial, :defer_pause, :plan_shares

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @plan = attributes['plan_config'] && Models::V2PlanConfig.new(attributes['plan_config'])
      @permissions = Models::BillingPermissions.new(attributes.fetch('permissions'))
      @source = attributes.fetch('source')
      @billing_info = attributes['billing_info'] && Models::V2BillingInfo.new(@id, attributes['billing_info'])
      @credit_card_info = attributes['credit_card_info'] && Models::V2CreditCardInfo.new(@id, attributes['credit_card_info'])
      @payment_intent = attributes['payment_intent'] && Models::PaymentIntent.new(attributes['payment_intent'])
      @owner = fetch_owner(attributes.fetch('owner'))
      @client_secret = attributes.fetch('client_secret')
      raw_addons = attributes['addons']

      # Debug: Let's see what we're working with
      puts "Total addons: #{raw_addons.count}"

      # Keep only addons that have a current_usage object
      usable_addons = raw_addons.select { |a| a['current_usage'] }

      # Debug: Check what we have after filtering
      puts "Usable addons (with current_usage): #{usable_addons.count}"

      # Split them by status
      non_expired = usable_addons.select { |a| a['current_usage']['status'] != 'expired' }
      expired = usable_addons.select { |a| a['current_usage']['status'] == 'expired' }

      # Debug: Check the split
      puts "Non-expired: #{non_expired.count}, Expired: #{expired.count}"

      # If debugging shows expired is empty but should have items, check the actual status values:
      if expired.empty? && non_expired.empty? && usable_addons.any?
        puts "Status values found: #{usable_addons.map { |a| a['current_usage']['status'] }.uniq}"
      end

      picked = if non_expired.any?
                 non_expired
               elsif expired.any?
                 # Sort by valid_to and take the latest (most recent date)
                 latest = expired.max_by { |a| a['current_usage']['valid_to'] || '1900-01-01' }
                 [latest].compact  # compact removes nil if max_by returns nil
               else
                 []
               end

      @addons = picked.map { |addon| Models::V2Addon.new(addon) }
      # @addons = attributes['addons'].select { |addon| addon['current_usage'] if addon['current_usage'] }.map { |addon| Models::V2Addon.new(addon) }
      refill = attributes['addons'].detect { |addon| addon['addon_config_id'] === 'auto_refill' } || {"enabled" => false}
      default_refill = @plan.respond_to?('available_standalone_addons') ?
        @plan.available_standalone_addons.detect { |addon| addon['id'] === 'auto_refill' } : nil

      refill['enabled'] = attributes['auto_refill_enabled']
      if default_refill
        refill['refill_threshold'] = default_refill['refill_threshold'] unless refill.key?('refill_threshold')
        refill['refill_amount'] = default_refill['refill_amount'] unless refill.key?('refill_amount')
      end
      @auto_refill = Models::AutoRefill.new(refill)
      @created_at = attributes.fetch('created_at')
      @status = attributes.fetch('status')
      @valid_to = attributes.fetch('valid_to')
      @canceled_at = attributes.fetch('canceled_at')
      @scheduled_plan_name = attributes.fetch('scheduled_plan')
      @cancellation_requested = attributes.fetch('cancellation_requested')
      current_trial = attributes.fetch('current_trial', nil)
      if current_trial
        @current_trial = Models::V2Trial.new(current_trial)
      end
      @defer_pause = attributes.fetch('defer_pause', false)
      @plan_shares = attributes['plan_shares'] && attributes['plan_shares'].map { |sp| Models::PlanShare.new(sp) }
    end
  end

  class Models::V2BillingInfo
    attr_reader :id, :address, :address2, :billing_email, :city, :company, :country, :first_name, :last_name, :state, :vat_id, :zip_code, :has_local_registration

    def initialize(id, attrs)
      @id = id
      @address = attrs.fetch('address')
      @address2 = attrs.fetch('address2')
      @billing_email = attrs.fetch('billing_email')
      @city = attrs.fetch('city')
      @company = attrs.fetch('company')
      @country = attrs.fetch('country')
      @first_name = attrs.fetch('first_name')
      @last_name = attrs.fetch('last_name')
      @state = attrs.fetch('state')
      @vat_id = attrs.fetch('vat_id')
      @zip_code = attrs.fetch('zip_code')
      @has_local_registration = attrs.fetch('has_local_registration', false)
    end
  end

  class Models::V2CreditCardInfo
    attr_reader :id, :card_owner, :expiration_date, :last_digits

    def initialize(id, attrs)
      @id = id
      @card_owner = attrs.fetch('card_owner')
      @expiration_date = attrs.fetch('expiration_date')
      @last_digits = attrs.fetch('last_digits')
    end
  end
end
