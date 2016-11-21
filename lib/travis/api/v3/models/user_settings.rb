module Travis::API::V3
  class Models::UserSettings < Models::JsonSlice
    child Models::UserSetting

    attribute :builds_only_with_travis_yml, Boolean, default: false
    attribute :build_pushes, Boolean, default: true
    attribute :build_pull_requests, Boolean, default: true
    attribute :maximum_number_of_builds, Integer, default: 0
    attribute :auto_cancel_pushes, Boolean, default: false
    attribute :auto_cancel_pull_requests, Boolean, default: false

    def repository_id
      parent && parent.id
    end
  end
end
