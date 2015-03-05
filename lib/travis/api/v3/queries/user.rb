module Travis::API::V3
  class Queries::User < Query
    params :id

    def find
      return Models::User.find_by_id(id) if id
      raise WrongParams, 'missing user.id'.freeze
    end
  end
end
