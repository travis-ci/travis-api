module Travis::API::V3
  class Services::FindRepository < Service
    def run
      raise NotFound, :repository unless repository and access_control.visible? repository
      Result.new(:repository, repository)
    end

    def repository
      raise EntityMissing, :repository if defined?(@repository) and @repository.nil?
      @repository ||= find_repository
    end

    def find_repository
      query(:repository).find
    end
  end
end
