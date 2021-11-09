# frozen_string_literal: true

module Travis
  module Models
    module Billing
      class V2Addon
        attr_reader :id, :name, :type, :addon_config, :refill_threshold, :refill_amount

        def initialize(attributes, addon_config)
          @id = attributes.fetch(:id)
          @name = attributes.fetch(:name)
          @type = attributes.fetch(:type)
          @current_usage = attributes.fetch(:current_usage) && V2AddonUsage.new(attributes.fetch(:current_usage))
          @addon_config = addon_config
          @refill_threshold = attributes.fetch(:refill_threshold)
          @refill_amount = attributes.fetch(:refill_amount)
        end

        def status
          @current_usage&.status
        end

        def quantity
          @current_usage&.quantity
        end

        def usage
          @current_usage&.usage
        end

        def active?
          @current_usage&.active?
        end

        def show_valid_to?
          user_license? && !free?
        end

        def valid_to
          @current_usage&.valid_to
        end

        def free?
          @addon_config.free?
        end

        def user_license?
          @type == 'user_license'
        end

        def credit_private?
          @type == 'credit_private'
        end

        def credit_public?
          @type == 'credit_public'
        end

        def config_id
          @addon_config.id
        end
      end
    end
  end
end
