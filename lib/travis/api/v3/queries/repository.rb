module Travis::API::V3
  class Queries::Repository < Query
    setup_sidekiq(:repo_sync, queue: :sync, class_name: "Travis::GithubSync::Worker")
    params :id, :slug

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

    private

    def find!
      return by_slug if slug
      return Models::Repository.find_by_id(id) if id
      raise WrongParams, 'missing repository.id'.freeze
    end

    def by_slug
      owner_name, name = slug.split('/')
      Models::Repository.where(owner_name: owner_name, name: name, invalidated_at: nil).first
    end
  end
end
