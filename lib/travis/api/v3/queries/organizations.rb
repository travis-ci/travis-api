module Travis::API::V3
  class Queries::Organizations < Query
    sortable_by :id, :login, :name, :github_id, :vcs_id
    params :role, prefix: :organization

    def for_member(user)
      orgs =  Models::Organization.joins(:users).where(users: user_condition(user))
      orgs = orgs.where(memberships: { role: role }) if role
      sort orgs
    end
  end
end
