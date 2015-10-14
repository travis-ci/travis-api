module Travis::API::V3
  class Queries::Organizations < Query
    sortable_by :id, :login, :name, :github_id

    def for_member(user)
      sort Models::Organization.joins(:users).where(users: user_condition(user))
    end
  end
end
