module Travis::API::V3
  class Queries::Organization < Query
    params :id

    def find
      return Models::Organization.find_by_id(id) if id
      raise WrongParams, 'missing organization.id'.freeze
    end
  end
end
