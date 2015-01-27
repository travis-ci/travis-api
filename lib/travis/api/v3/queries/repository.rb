module Travis::API::V3
  class Queries::Repository < Query
    params :id

    def find
      return ::Repository.find_by_id(id) if id
      raise WrongParams
    end
  end
end
