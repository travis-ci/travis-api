module Travis::API::V3
  class Queries::StarredRepositories < Query

    def for_user(user)
      all.where(<<-SQL, 'User'.freeze, user.id)
      SQL
    end

  end
end
