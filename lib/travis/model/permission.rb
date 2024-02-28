require 'core_ext/active_record/none_scope'
require 'travis/model'

class Permission < Travis::Model
  self.table_name = 'permissions'
  ROLES = %w(admin push pull)

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

  belongs_to :user
  belongs_to :repository
end
