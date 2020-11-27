# frozen_string_literal: true

module Travis
  module Models
    module Billing
      class V2AddonUsage
        STATUSES = [
          'subscribed',
          'pending',
          'expired'
        ].freeze

        attr_reader :id, :quantity, :usage, :status

        def initialize(attributes)
          @id = attributes.fetch(:id)
          @quantity = attributes.fetch(:addon_quantity)
          @usage = attributes.fetch(:addon_usage)
          @status = attributes.fetch(:status)
          @valid_to = attributes.fetch(:valid_to)
        end

        def active?
          @status == 'subscribed' && (!@valid_to || Time.parse(@valid_to).future?)
        end
      end
    end
  end
end
