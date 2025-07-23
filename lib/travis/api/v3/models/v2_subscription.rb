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

      # Debug: Initial state
      puts "=== ADDON SELECTION DEBUG ==="
      puts "Total raw addons: #{raw_addons.count}"

      # Helper method to normalize current_usage to array
      def normalize_current_usage(addon)
        return [] unless addon['current_usage']

        # If it's already an array, return it; otherwise wrap in array
        addon['current_usage'].is_a?(Array) ? addon['current_usage'] : [addon['current_usage']]
      end

      # Helper to get the latest valid_to date from an addon's current_usages
      def latest_valid_to(addon)
        usages = normalize_current_usage(addon)
        return '1900-01-01' if usages.empty?

        usages.map { |u| u['valid_to'] || '1900-01-01' }.max
      end

      # Group addons by type first
      addons_by_type = raw_addons.group_by { |addon| addon['type'] }

      selected_addons = []

      # Process each type independently
      addons_by_type.each do |type, type_addons|
        puts "\n--- Processing type: #{type} ---"
        count = type_addons&.count || 0
        puts "  Type '#{type}': #{count} addons"

        # Filter addons with at least one current_usage
        usable_addons = type_addons.select do |addon|
          usages = normalize_current_usage(addon)
          usages.any?
        end

        puts "  Total addons for type: #{type_addons.count}"
        puts "  Addons with current_usage: #{usable_addons.count}"

        # Skip if no usable addons for this type
        if usable_addons.empty?
          puts "  No usable addons for type '#{type}', skipping..."
          next
        end

        # Split by expiration status
        # An addon is considered non-expired if it has at least one non-expired usage
        non_expired = usable_addons.select do |addon|
          usages = normalize_current_usage(addon)
          usages.any? { |usage| usage['status'] != 'expired' }
        end

        # An addon is considered expired if ALL its usages are expired
        expired = usable_addons.select do |addon|
          usages = normalize_current_usage(addon)
          usages.all? { |usage| usage['status'] == 'expired' }
        end

        puts "  Non-expired: #{non_expired.count}"
        puts "  Expired: #{expired.count}"

        # Debug: Show actual status values if neither category has items
        if non_expired.empty? && expired.empty? && usable_addons.any?
          all_statuses = usable_addons.flat_map do |addon|
            normalize_current_usage(addon).map { |u| u['status'] }
          end.uniq
          puts "  WARNING: No addons categorized! Status values found: #{all_statuses.inspect}"
        end

        # Apply selection logic for this type
        if non_expired.any?
          # Case 1: Include all non-expired addons for this type
          puts "  ✓ Including #{non_expired.count} non-expired addon(s)"
          selected_addons.concat(non_expired)
        elsif expired.any?
          # Case 2: Include only the latest expired addon for this type
          # Find the addon with the most recent valid_to across all its current_usages
          latest_expired = expired.max_by { |addon| latest_valid_to(addon) }

          if latest_expired
            puts "  ✓ Including latest expired addon (latest valid_to: #{latest_valid_to(latest_expired)})"
            selected_addons << latest_expired
          else
            puts "  Could not find latest expired addon"
          end
        else
          puts "  No addons selected for type '#{type}'"
        end
      end

      puts "\n=== FINAL RESULT ==="
      puts "Total selected addons: #{selected_addons.count}"
      selected_addons.group_by { |a| a['type'] }.each do |type, addons|
        count = addons&.count || 0
        puts "  Type '#{type}': #{count} addon(s)"
      end

      # Convert to model objects
      @addons = selected_addons.map { |addon| Models::V2Addon.new(addon) }
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
