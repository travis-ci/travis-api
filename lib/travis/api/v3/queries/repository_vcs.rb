module Travis::API::V3
  class Queries::RepositoryVcs < Query
    params :vcs_id

    def find
      @find ||= find!
    end

    private

    def find!
      return by_vcs_id if vcs_id
      raise WrongParams, 'missing repository_vcs.vcs_id'.freeze
    end

    def by_vcs_id
      Models::Repository.where(
                          "repositories.vcs_id = ? "\
                          "and lower(repositories.vcs_type) = ? "\
                          "and repositories.invalidated_at is null",
                          vcs_id,
                          "#{provider.downcase}repository"
                        )
                        .order("updated_at desc, vcs_slug asc, owner_name asc, name asc, vcs_type asc")
                        .first
    end

    def provider
      params['provider'] || 'github'
    end
  end
end
