module Travis::API::V3
  class Models::UserSetting < Models::JsonPair
    def public?
      true
    end

    def repository_id
      parent && parent.id
    end
  end
end
