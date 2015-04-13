module Travis::API::V3
  class Queries::User < Query
    params :id, :login

    def find
      return Models::User.find_by_id(id)       if id
      return Models::User.find_by_login(login) if login
      raise WrongParams, 'missing user.id or user.login'.freeze
    end
  end
end
