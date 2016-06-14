module Travis::API::V3
  class Models::EnvVars < Travis::Settings::Collection
    model Models::EnvVar

    def repository
      @repository ||= Models::Repository.find(additional_attributes[:repository_id])
    end

    undef :to_hash
  end
end
