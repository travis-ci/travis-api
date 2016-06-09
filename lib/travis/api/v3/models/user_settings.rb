module Travis::API::V3
  class Models::UserSettings < Travis::Settings::Model
    attribute :builds_only_with_travis_yml, Boolean, default: false
    attribute :build_pushes, Boolean, default: true
    attribute :build_pull_requests, Boolean, default: true
    attribute :maximum_number_of_builds, Integer, default: 0
  end
end
