# frozen_string_literal: true

module Travis
  module Models
    module Billing
      class V2AddonConfig
        attr_reader :id, :name, :price, :type

        def initialize(attributes)
          @id = attributes.fetch(:id)
          @name = attributes.fetch(:name)
          @price = attributes.fetch(:price)
          @type = attributes.fetch(:type)
          @free = attributes.fetch(:free)
        end

        def free?
          @free
        end
      end
    end
  end
end
