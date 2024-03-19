module Travis::API::V3
  class Models::UserSetting < Models::JsonPair

    def public?
      true
    end

    def repository_id
      parent && parent.id
    end

    def repository
      return unless repository_id
      V3::Models::Repository.find(repository_id)
    end
  end
end
