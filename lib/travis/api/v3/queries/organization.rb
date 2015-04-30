module Travis::API::V3
  class Queries::Organization < Query
    params :id, :login

    def find
      return Models::Organization.find_by_id(id) if id
      return Models::Organization.where('lower(login) = ?'.freeze, login.downcase).first if login
      raise WrongParams, 'missing organization.id or organization.login'.freeze
    end
  end
end
