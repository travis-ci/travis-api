module Travis::API::V3
  class Queries::Settings < Query
    params :builds_only_with_travis_yml, :build_pushes, :build_pull_requests, :maximum_number_of_builds, prefix: :settings

    def find(repository)
      Models::Settings.new(repository)
    end

    def update(repository)
      settings = find(repository)
      settings.update(settings_params)
      settings
    end
  end
end
