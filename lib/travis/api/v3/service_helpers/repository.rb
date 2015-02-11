module Travis::API::V3
  module ServiceHelpers::Repository
    def repository
      @repository ||= find_repository
    end

    def find_repository
      not_found(true, :repository)  unless repo = query(:repository).find
      not_found(false, :repository) unless access_control.visible? repo
      repo
    end
  end
end
