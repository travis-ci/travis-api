# frozen_string_literal: true

module Travis
  module Models
    module Billing
      class V2Subscription
        SOURCES = [
          'stripe',
          'manual',
          'github'
        ].freeze
        STATUSES = [
          'subscribed',
          'pending',
          'expired',
          'canceled',
          'incomplete',
          'incomplete_expired',
          'past_due'
        ].freeze
        FREE_USERS_FOR_PAID = 'users_free_for_paid_plans'

        attr_reader :id, :source, :coupon, :created_at, :valid_to, :owner_id, :owner_type, :owner, :billing_email,
                    :billing_address, :vat_id, :changes, :concurrency_limit, :status, :plan_config, :addons,
                    :addon_configs, :addable_addon_configs, :auto_refill_enabled

        def initialize(attributes)
          attributes.deep_symbolize_keys!
          @id = attributes.fetch(:id)
          @permissions = attributes.fetch(:permissions)
          @plan_config = attributes.fetch(:plan_config)
          @source = attributes.fetch(:source)
          @coupon = attributes.fetch(:coupon)
          @created_at = attributes.fetch(:created_at)
          @valid_to = attributes.fetch(:valid_to)
          @status = attributes.fetch(:status)
          concurrency = attributes.fetch(:concurrency_limit)
          @concurrency_limit = concurrency || @plan_config.fetch(:concurrency_limit)
          @owner_id = attributes[:owner][:id]
          @owner_type = attributes[:owner][:type]
          @owner = @owner_type == 'User' ? ::User.find_by(id: @owner_id) : ::Organization.find_by(id: @owner_id)
          if attributes[:billing_info].present?
            @billing_email = attributes[:billing_info][:billing_email]
            @vat_id = attributes[:billing_info][:vat_id]
            @billing_address = attributes[:billing_info].slice(:zip_code, :address, :address2, :city, :state, :country)
          end

          @addon_configs = @plan_config.fetch(:addon_configs)
          @addable_addon_configs = (@plan_config[:addon_configs] + @plan_config[:all_available_addons]).uniq
          @addable_addon_configs.reject! { |ac| ac[:type] == 'user_license' }
          unless hybrid?
            @plan_config[:all_available_addons] << {
              id: FREE_USERS_FOR_PAID,
              name: 'Free users',
              price: 0,
              type: 'user_license',
              free: true
            }
          end
          standalone_addon_configs = @plan_config.fetch(:all_available_addons)
          unless attributes[:addons].empty?
            @addons = attributes.fetch(:addons).map do |addon_data|
              if addon_data[:addon_config_id] == 'auto_refill'
                addon_config = {
                  id: addon_data[:addon_config_id],
                  name: addon_data[:name],
                  price: 0,
                  type: addon_data[:type],
                  free: false
                }
              else
                addon_config = addon_configs.detect { |config| config[:id] == addon_data[:addon_config_id] } || standalone_addon_configs.detect { |config| config[:id] == addon_data[:addon_config_id] }
              end
              next unless addon_config
              V2Addon.new(addon_data, V2AddonConfig.new(addon_config))
            end
            @addons = @addons.compact
          end

          @changes = attributes.fetch(:plan_changes).map { |plan_change_data| V2PlanChange.new(plan_change_data) }
          @auto_refill_enabled = attributes.fetch(:auto_refill_enabled, false)
        end

        def active?
          true
        end

        def github?
          @source == 'github'
        end

        def manual?
          @source == 'manual'
        end

        def hybrid?
          @plan_config[:plan_type] == 'hybrid' || @plan_config[:plan_type] == 'hybrid annual'
        end

        def recurring?
          @addon_configs.any? { |addon_config| addon_config[:recurring] }
        end

        def can_create_addons?
          !addable_addon_configs.empty?
        end

        def can_create_free_user_license?
          @plan_config[:plan_type] == 'metered' && !@plan_config[:starting_price].zero? && @addons.select { |addon| addon.addon_config.id == FREE_USERS_FOR_PAID }.empty?
        end

        def can_read?
          @permissions['read']
        end

        def can_write?
          @permissions['write']
        end

        def plan_name
          @plan_config[:name]
        end

        def plan_id
          @plan_config[:id]
        end

        def supported_addons
          addons ? addons.select { |addon| addon.addon_config.present? } : []
        end
      end
    end
  end
end
