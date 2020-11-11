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

        attr_reader :id, :source, :coupon, :created_at, :valid_to, :owner_id, :owner_type, :owner, :billing_email,
                    :billing_address, :vat_id, :changes, :concurrency_limit, :plan_config, :addons

        def initialize(attributes)
          @id = attributes.fetch(:id)
          @permissions = attributes.fetch(:permissions)
          @plan_config = attributes.fetch(:plan_config)
          @source = attributes.fetch(:source)
          @coupon = attributes.fetch(:coupon)
          @created_at = attributes.fetch(:created_at)
          @valid_to = attributes.fetch(:valid_to)
          @concurrency_limit = attributes.fetch(:concurrency_limit, @plan_config.fetch(:concurrency_limit))
          @owner_id = attributes[:owner][:id]
          @owner_type = attributes[:owner][:type]
          @owner = @owner_type == 'User' ? ::User.find_by(id: @owner_id) : ::Organization.find_by(id: @owner_id)
          if attributes[:billing_info].present?
            @billing_email = attributes[:billing_info][:billing_email]
            @vat_id = attributes[:billing_info][:vat_id]
            @billing_address = attributes[:billing_info].slice(:zip_code, :address, :address2, :city, :state, :country)
          end

          addon_configs = @plan_config.fetch(:addon_configs)
          standalone_addon_configs = @plan_config.fetch(:available_standalone_addons)
          @addons = attributes.fetch(:addons).map do |addon_data|
            addon_config = addon_configs.detect { |config| config[:id] == addon_data[:addon_config_id] } || standalone_addon_configs.detect { |config| config[:id] == addon_data[:addon_config_id] }

            V2Addon.new(addon_data, V2AddonConfig.new(addon_config))
          end
          @changes = attributes.fetch(:plan_changes).map { |plan_change_data| V2PlanChange.new(plan_change_data) }
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

        def supported_addons
          addons.select { |addon| addon.addon_config.present? }
        end
      end
    end
  end
end
