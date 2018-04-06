module Travis::API::V3
  class Queries::Organization < Query
    params :id, :login, :github_id

    def find
      return Models::Organization.find_by_id(id) if id
      return Models::Organization.find_by_github_id(github_id) if github_id
      return Models::Organization.where('lower(login) = ?'.freeze, login.downcase).order("id DESC").first if login
      raise WrongParams, 'missing organization.id or organization.login'.freeze
    end
  end
end
