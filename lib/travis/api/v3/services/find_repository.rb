module Travis::API::V3
  class Services::FindRepository < Service
    params :id, :github_id, :slug, optional: true

    def run
      raise NotFound unless repository and access_control.visible? repository
      Result.new(repository)
    end

    def repository
      raise EntityMissing if defined?(@repository) and @repository.nil?
      @repository ||= find_repository
    end

    def find_repository
      return ::Repository.find_by_id(id)               if id
      return ::Repository.find_by_github_id(github_id) if github_id
      return ::Repository.by_slug(slug).first          if slug
      raise WrongParams
    end
  end
end
