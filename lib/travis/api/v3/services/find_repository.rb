module Travis::API::V3
  class Services::FindRepository < Service
    result_type :repository

    def run!
      repository if repository and access_control.visible? repository
    end

    def repository
      not_found(true) if defined?(@repository) and @repository.nil?
      @repository ||= find_repository
    end

    def find_repository
      query.find
    end
  end
end
