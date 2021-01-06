# frozen_string_literal: true

module Travis
  module Models
    module Billing
      class V2PlanChange
        attr_reader :id, :plan_changes, :addon_changes, :user_id, :created_at, :change_reason

        def initialize(attributes)
          @id = attributes.fetch(:id)
          @plan_changes = attributes.fetch(:plan_changes, {})
          @addon_changes = attributes.fetch(:addon_changes, [])
          @user_id = attributes.fetch(:user_id)
          @created_at = Time.parse(attributes.fetch(:created_at))
          @change_reason = attributes.fetch(:change_reason)
        end

        def user
          return @user if defined?(@user)

          @user = ::User.find_by(id: @user_id)
        end
      end
    end
  end
end
