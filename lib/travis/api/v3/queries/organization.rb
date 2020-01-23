module Travis::API::V3
  class Queries::Organization < Query
    params :id, :login, :github_id

    def find
      return Models::Organization.find_by_id(id) if id
      return Models::Organization.find_by(vcs_id: github_id) || Models::Organization.find_by(github_id: github_id) if github_id
      return Models::Organization.where(
        'lower(login) = ? and lower(vcs_type) = ?'.freeze,
        login.downcase,
        provider.downcase + 'organization'
      ).order("id DESC").first if login
      raise WrongParams, 'missing organization.id or organization.login'.freeze
    end

    private

    def provider
      params['provider'] || 'github'
    end

  end
end
