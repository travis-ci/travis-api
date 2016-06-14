module Travis::API::V3
  class Models::Permission < Model
    ROLES = %w(admin push pull)

    belongs_to :user
    belongs_to :repository

    class << self
      def by_roles(roles)
        roles = Array(roles).select { |role| ROLES.include?(role.to_s) }
        roles.empty? ? none : where(has_roles(roles))
      end

      def has_roles(roles)
        roles.inject(has_role(roles.shift)) do |sql, role|
          sql.or(has_role(role))
        end
      end

      def has_role(role)
        arel_table[role].eq(true)
      end
    end
  end
end
