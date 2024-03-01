module Travis::API::V3
  class Queries::Repository < Query
    setup_sidekiq(:repo_sync, queue: :sync, class_name: "Travis::GithubSync::Worker")
    params :id, :slug, :server_type

    def find
      @find ||= find!
    end

    def star(current_user)
      repository = find
      starred = Models::Star.where(repository_id: repository.id, user_id: current_user.id).first
      Models::Star.create(repository_id: repository.id, user_id: current_user.id) unless starred
      repository
    end

    def unstar(current_user)
      repository = find
      starred = Models::Star.where(repository_id: repository.id, user_id: current_user.id).first
      starred.delete if starred
      repository
    end

    def sync(current_user)
      repository = find
      perform_async(:repo_sync, :sync_repo, repo_id: repository.id, user_id: current_user.id)
      repository
    end

    def update(attrs)
      repository = find
      repository.update!(attrs)
      repository
    end

    private

    def find!
      return by_slug if slug
      return Models::Repository.find_by_id(id) if id && !id.match(/\D/)
      raise WrongParams, 'missing repository.id'.freeze
    end

    def by_slug
      owner_name, repo_name = slug.split('/')
      repos = Models::Repository.where(
        "(lower(repositories.vcs_slug) = ? "\
        "or (lower(repositories.owner_name) = ? and lower(repositories.name) = ?)) "\
        "and lower(repositories.vcs_type) = ? "\
        "and repositories.invalidated_at is null",
        slug.downcase,
        owner_name.downcase,
        repo_name.downcase,
        "#{provider.downcase}repository"
      )
      repos = repos.by_server_type(server_type) if server_type && provider == 'assembla'

      repos.order("updated_at desc, vcs_slug asc, owner_name asc, name asc, vcs_type asc")
           .first
    end

    def provider
      params['provider'] || 'github'
    end
  end
end
